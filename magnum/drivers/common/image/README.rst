Pre-requisites to run diskimage-builder
---------------------------------------
For diskimage-builder to work, following packages need to be
present:

* python-dev
* build-essential
* python-pip
* kpartx
* python-lzma
* qemu-utils
* yum
* yum-utils
* python-yaml

For Debian/Ubuntu systems, use::

    apt-get install python-dev build-essential python-pip kpartx python-lzma \
                    qemu-utils yum yum-utils python-yaml git curl

For CentOS and Fedora < 22, use::

    yum install python-dev build-essential python-pip kpartx python-lzma qemu-utils yum yum-utils python-yaml

For Fedora >= 22, use::

    dnf install python-devel @development-tools python-pip kpartx python-backports-lzma @virtualization yum yum-utils python-yaml
