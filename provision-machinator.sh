#!/bin/bash
set -euxo pipefail
cd /vagrant/machinator

cp /vagrant/shared/machines.json "$HOME/machines.json"

docker build -t machinator .

docker rm -f machinator || true

docker run \
    -d \
    --restart unless-stopped \
    --name machinator \
    -v "$HOME/machines.json:/machines.json:ro" \
    -v /var/lib/misc/dnsmasq.leases:/dnsmasq.leases:ro \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -p 8000:8000 \
    machinator
