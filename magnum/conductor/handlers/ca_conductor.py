# Copyright 2015 NEC Corporation.  All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

import six
import uuid

from oslo_log import log as logging
from pycadf import cadftaxonomy as taxonomy

from magnum.common import clients
from magnum.conductor.handlers import cluster_conductor
from magnum.conductor.handlers.common import cert_manager
from magnum.conductor import utils as conductor_utils
from magnum.drivers.common import driver
from magnum import objects
LOG = logging.getLogger(__name__)


class Handler(object):
    """Magnum CA RPC handler.

    These are the backend operations. They are executed by the backend service.
    API calls via AMQP (within the ReST API) trigger the handlers to be called.

    """

    def __init__(self):
        super(Handler, self).__init__()

    def sign_certificate(self, context, cluster, certificate):
        LOG.debug("Creating self signed x509 certificate")
        signed_cert = cert_manager.sign_node_certificate(cluster,
                                                         certificate.csr,
                                                         context=context)
        certificate.pem = signed_cert
        return certificate

    def get_ca_certificate(self, context, cluster):
        ca_cert = cert_manager.get_cluster_ca_certificate(cluster,
                                                          context=context)
        certificate = objects.Certificate.from_object_cluster(cluster)
        certificate.pem = ca_cert.get_certificate()
        return certificate

    def replace_certificates(self, context, cluster):
        cert_manager.generate_certificates_to_cluster(cluster,
                                                      context=context)
        cluster.save()

        conductor_utils.notify_about_cluster_operation(
            context, taxonomy.ACTION_UPDATE, taxonomy.OUTCOME_PENDING)

        stack_update_fields = {
            'existing': True,
            'parameters': {'replace_certs_param': six.text_type(uuid.uuid4())}
        }

        osc = clients.OpenStackClients(context)
        osc.heat().stacks.update(cluster.stack_id, **stack_update_fields)
