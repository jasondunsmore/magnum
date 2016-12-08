#!/bin/bash

set -eux
set -o pipefail

SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR=$(mktemp -d)
pushd $TMPDIR

# Heat software deployment elements
git clone https://github.com/openstack/heat-templates.git

# TripleO os-*-config elements
git clone https://git.openstack.org/openstack/tripleo-image-elements.git

# Grab diskimage builder and utils
git clone https://git.openstack.org/openstack/diskimage-builder.git
git clone https://git.openstack.org/openstack/dib-utils.git

# Use diskimage-builder to create image
export PATH="${TMPDIR}/dib-utils/bin:$PATH"
export PATH="${TMPDIR}/diskimage-builder/bin:$PATH"
export ELEMENTS_PATH="${TMPDIR}/diskimage-builder/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${TMPDIR}/tripleo-image-elements/\
elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${TMPDIR}/heat-templates/hot/\
software-config/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${TMPDIR}/rpc-magnum/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:$(dirname ${SRCDIR})"
export DIB_RELEASE=24
export DIB_IMAGE_SIZE=2.5
export DIB_YUM_REPO_CONF="${SRCDIR}/yum.repos.d/kubernetes.repo \
${SRCDIR}/yum.repos.d/docker.repo"
export DIB_CLOUD_INIT_DATASOURCES="OpenStack"
IMAGEFILE=${TMPDIR}/fedora-${DIB_RELEASE}-magnum-dib
disk-image-create -x -o $IMAGEFILE fedora-magnum

popd
echo "Image successfully created at ${IMAGEFILE}.qcow2"
