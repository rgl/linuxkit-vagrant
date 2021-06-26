#!/bin/bash
set -euxo pipefail


ip_address="${1:-10.10.0.2}"; shift || true
dhcp_range="${1:-10.10.0.100,10.10.0.200,10m}"; shift || true
external_ip_address="${1:-10.3.0.2}"; shift || true
external_dhcp_range="${1:-10.3.0.100,10.3.0.200,10m}"; shift || true


#
# provision the DHCP/TFTP server.
# see http://www.thekelleys.org.uk/dnsmasq/docs/setup.html
# see http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
# see https://wiki.archlinux.org/title/Dnsmasq

default_dns_resolver="$(systemd-resolve --status | awk '/DNS Servers: /{print $3}')" # recurse queries through the default vagrant environment DNS server.
apt-get install -y --no-install-recommends dnsmasq
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm /etc/resolv.conf
echo 'nameserver 127.0.0.1' >/etc/resolv.conf
install -d /srv/pxe
cat >/etc/dnsmasq.d/local.conf <<EOF
# NB DHCP leases are stored at /var/lib/misc/dnsmasq.leases

# verbose
log-dhcp
log-queries

# ignore host settings
no-resolv
no-hosts

# DNS server
server=$default_dns_resolver
domain=$(hostname --domain) # NB this is actually used by the DHCP server, but its related to our DNS domain, so I leave it here.
auth-zone=$(hostname --domain)
auth-server=$(hostname --fqdn)
host-record=$(hostname --fqdn),$ip_address

# listen on specific interfaces
bind-interfaces

# TFTP
enable-tftp
tftp-root=/srv/pxe

# UEFI HTTP (e.g. X86J4105)
dhcp-match=set:efi64-http,option:client-arch,16 # x64 UEFI HTTP (16)
dhcp-option-force=tag:efi64-http,60,HTTPClient
dhcp-boot=tag:efi64-http,tag:eth1,http://$ip_address/assets/ipxe.efi
dhcp-boot=tag:efi64-http,tag:eth2,http://$external_ip_address/assets/ipxe.efi

# BIOS/UEFI TFTP PXE (e.g. EliteDesk 800 G2)
# NB there's was a snafu between 7 and 9 in rfc4578 thas was latter fixed in
#    an errata.
#    see https://www.rfc-editor.org/rfc/rfc4578.txt
#    see https://www.rfc-editor.org/errata_search.php?rfc=4578
#    see https://www.iana.org/assignments/dhcpv6-parameters/dhcpv6-parameters.xhtml#processor-architecture
dhcp-match=set:bios,option:client-arch,0 # BIOS x86 (0)
dhcp-boot=tag:bios,undionly.kpxe
dhcp-match=set:efi32,option:client-arch,6 # EFI x86 (6)
dhcp-boot=tag:efi32,ipxe.efi
dhcp-match=set:efi64,option:client-arch,7 # EFI x64 (7)
dhcp-boot=tag:efi64,ipxe.efi
dhcp-match=set:efibc,option:client-arch,9 # EFI EBC (9)
dhcp-boot=tag:efibc,ipxe.efi

# iPXE HTTP (e.g. OVMF)
dhcp-userclass=set:ipxe,iPXE
dhcp-boot=tag:ipxe,tag:bios,tag:eth1,http://$ip_address/boot.ipxe
dhcp-boot=tag:ipxe,tag:bios,tag:eth2,http://$external_ip_address/boot.ipxe
dhcp-boot=tag:ipxe,tag:efi64,tag:eth1,http://$ip_address/boot.ipxe
dhcp-boot=tag:ipxe,tag:efi64,tag:eth2,http://$external_ip_address/boot.ipxe

# DHCP (internal network with virtual machines)
interface=eth1
dhcp-range=tag:eth1,$dhcp_range
EOF

if ip link show eth2 >/dev/null 2>&1; then
    cat >>/etc/dnsmasq.d/local.conf <<EOF

# DHCP (external network with physical machines)
interface=eth2
dhcp-range=tag:eth2,$external_dhcp_range
EOF
fi


#
# register the machines and start dnsmasq.

mkdir -p /var/lib/matchbox/{assets,groups,profiles,ignition,cloud,generic}
python3 /vagrant/modules/pxe_server_register_machines.py
systemctl restart dnsmasq


#
# install matchbox.
# see https://github.com/poseidon/matchbox

docker run \
    -d \
    --restart unless-stopped \
    --name matchbox \
    --net host \
    -v /var/lib/matchbox:/var/lib/matchbox:Z \
    quay.io/poseidon/matchbox:v0.9.0 \
        -address=0.0.0.0:80 \
        -log-level=debug
