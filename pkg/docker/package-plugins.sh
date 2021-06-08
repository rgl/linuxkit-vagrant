#!/bin/ash
set -euxo pipefail

DIND_VERSION="${1:-20.10.7}"; shift || true
LOKI_DOCKER_DRIVER_VERSION="${1:-2.2.1}"; shift || true
running_from_docker="${1:-no}"; shift || true

if [ "$running_from_docker" == 'yes' ]; then
    # wait for docker to be ready.
    while ! docker info >/dev/null 2>&1; do sleep 3; done

    # install the loki docker log driver plugin.
    # see https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
    docker plugin install \
        --alias loki \
        --grant-all-permissions \
        "grafana/loki-docker-driver:$LOKI_DOCKER_DRIVER_VERSION" \
            LOG_LEVEL=debug

    # package plugins.
    cd /var/lib/docker/plugins
    rm -f /host/tmp/docker-plugins.tgz
    ls . | awk '/^[a-f0-9]{64}$/{print $1}' | tar czT - >/host/tmp/docker-plugins.tgz
else
    # start dind, execute ourselfs to package the plugins, stop dind.
    mkdir -p tmp
    container_id="$(docker run --rm --detach --privileged -v "$PWD:/host" docker:$DIND_VERSION-dind)"
    docker exec "$container_id" ash /host/package-plugins.sh \
        "$DIND_VERSION" \
        "$LOKI_DOCKER_DRIVER_VERSION" \
        yes
    docker stop "$container_id"
fi
