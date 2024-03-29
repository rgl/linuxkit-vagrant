#!/bin/bash
set -euxo pipefail

loki_ip_address="${1:-10.10.0.2}"

# see https://github.com/grafana/grafana/releases
# see https://hub.docker.com/r/grafana/grafana/tags
grafana_version="8.1.4"

mkdir -p grafana/datasources
cd grafana

# configure grafana.
# see https://grafana.com/docs/grafana/latest/administration/configure-docker/
# see https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources
# see https://grafana.com/docs/grafana/latest/datasources/loki/#configure-the-data-source-with-provisioning
sed -E "s,@@loki_base_url@@,http://$loki_ip_address:3100,g" /vagrant/grafana-datasources.yml \
    >datasources/datasources.yml

# start grafana.
# see https://grafana.com/docs/grafana/latest/installation/docker/
docker run \
    -d \
    --restart unless-stopped \
    --name grafana \
    -p 3000:3000 \
    -v $PWD/datasources:/etc/grafana/provisioning/datasources \
    grafana/grafana:$grafana_version
