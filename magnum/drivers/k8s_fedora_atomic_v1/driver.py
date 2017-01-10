# Copyright 2016 Rackspace Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import six
import uuid

from pycadf import cadftaxonomy as taxonomy

from magnum.common import clients
from magnum.conductor.handlers.common import cert_manager
from magnum.conductor import utils as conductor_utils
from magnum.drivers.heat import driver
from magnum.drivers.k8s_fedora_atomic_v1 import template_def


class Driver(driver.HeatDriver):

    @property
    def provides(self):
        return [
            {'server_type': 'vm',
             'os': 'fedora-atomic',
             'coe': 'kubernetes'},
        ]

    def get_template_definition(self):
        return template_def.AtomicK8sTemplateDefinition()

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
