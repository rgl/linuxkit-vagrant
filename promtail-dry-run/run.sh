#!/bin/bash
set -euxo pipefail

cd "$(dirname "$0")"

# run promtail in dry mode and show the results in stdout.
docker run --rm \
    --name promtail-dry-run \
    -v $PWD/log:/host/var/log:ro \
    -v $PWD/..:/var/run/promtail:ro \
    grafana/promtail:2.2.1 \
        --dry-run \
        -config.file /var/run/promtail/promtail-config.yml \
    2>/dev/null &
sleep 15
docker stop promtail-dry-run
