#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

"""Utility for fetching a resource (e.g. a manifest) from a URL."""

from oslo_log import log as logging
import requests
from requests import exceptions
from six.moves import urllib

from magnum.common import exception
import magnum.conf
from magnum.i18n import _
from magnum.i18n import _LE
from magnum.i18n import _LI

CONF = magnum.conf.CONF
LOG = logging.getLogger(__name__)


class URLFetchError(exception.Invalid, IOError):
    pass


def get(url, allowed_schemes=('http', 'https')):
    """Get the data at the specified URL.

    The URL must use the http: or https: schemes.
    The file: scheme is also supported if you override
    the allowed_schemes argument.
    Raise an IOError if getting the data fails.
    """
    LOG.info(_LI('Fetching data from %s'), url)

    components = urllib.parse.urlparse(url)

    if components.scheme not in allowed_schemes:
        raise URLFetchError(_('Invalid URL scheme %s') % components.scheme)

    if components.scheme == 'file':  # nosec
        try:
            return urllib.request.urlopen(url).read()
        except urllib.error.URLError as uex:
            raise URLFetchError(_('Failed to retrieve manifest: %s') % uex)

    try:
        resp = requests.get(url, stream=True)
        resp.raise_for_status()

        # We cannot use resp.text here because it would download the
        # entire file, and a large enough file would bring down the
        # engine.  The 'Content-Length' header could be faked, so it's
        # necessary to download the content in chunks to until
        # max_manifest_size is reached.  The chunk_size we use needs
        # to balance CPU-intensive string concatenation with accuracy
        # (eg. it's possible to fetch 1000 bytes greater than
        # max_manifest_size with a chunk_size of 1000).
        reader = resp.iter_content(chunk_size=1000)
        result = ""
        for chunk in reader:
            result += chunk
            if len(result) > CONF.max_manifest_size:
                raise URLFetchError(_LE("Manifest exceeds maximum allowed"
                                        "size (%s bytes)") %
                                    CONF.max_manifest_size)
        return result

    except exceptions.RequestException as ex:
        raise URLFetchError(_('Failed to retrieve manifest: %s') % ex)
