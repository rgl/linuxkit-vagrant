#!/bin/sh
set -euo pipefail

# execute dockerd in background.
# NB to install the plugins we need a running dockerd. we temporarily execute
#    one in background to install the plugins.
export DOCKER_HOST=unix:///dockerd.install.sock
cat >/dockerd.install.json <<EOF
{}
EOF
"$@" \
    --config-file /dockerd.install.json \
    --host $DOCKER_HOST \
    &
dockerd_pid=$!

# wait for dockerd to be ready.
while ! docker info --format '{{.ServerVersion}}' >/dev/null 2>&1; do sleep 1; done

# install the loki log driver plugin.
# see https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
docker plugin install \
    --grant-all-permissions \
    --alias loki \
    grafana/loki-docker-driver:2.3.0 \
        LOG_LEVEL=debug

# shutdown dockerd.
kill $dockerd_pid
while kill -0 $dockerd_pid >/dev/null 2>&1; do sleep 1; done
rm -f /dockerd.install.json
unset DOCKER_HOST

# execute the final dockerd.
# NB it now has the plugins installed and uses the user configuration.
exec "$@"
