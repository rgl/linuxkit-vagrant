#!/bin/bash
set -euxo pipefail

cd /vagrant/pkg/docker

DIND_VERSION="${1:-20.10.7}"; shift || true
LOKI_DOCKER_DRIVER_VERSION="${1:-2.2.1}"; shift || true

# package the plugins into a tarball.
# NB bundling docker plugins into a dind image is somewhat of an oddball.
# NB this implementation only packages the current arch.
# see https://github.com/linuxkit/linuxkit/issues/3687
bash package-plugins.sh "$DIND_VERSION" "$LOKI_DOCKER_DRIVER_VERSION"

# build the dind image with included plugins.
docker build -t local/docker:$DIND_VERSION-dind .
