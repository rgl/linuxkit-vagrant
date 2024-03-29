#!/bin/bash
set -euo pipefail

host_ip_address="$(ip addr show eth1 | perl -n -e'/ inet (\d+(\.\d+)+)/ && print $1')"
first_vm_mac="$((jq -r '.[] | select(.type == "virtual") | .mac' | head -1) </vagrant/shared/machines.json)"

function title {
    cat <<EOF

########################################################################
#
# $*
#

EOF
}

title 'matchbox addresses'
cat <<EOF
http://$host_ip_address/ipxe?mac=$first_vm_mac
http://$host_ip_address/metadata?mac=$first_vm_mac
http://$host_ip_address/generic?mac=$first_vm_mac
EOF

title 'addresses'
python3 <<EOF
from tabulate import tabulate

headers = ('service', 'address', 'username', 'password')

def info():
    yield ('grafana',       'http://$host_ip_address:3000', 'admin', 'admin')
    yield ('meshcommander', 'http://$host_ip_address:4000', None,    None)
    yield ('machinator',    'http://$host_ip_address:8000', None,    None)

print(tabulate(info(), headers=headers))
EOF
