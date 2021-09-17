#!/bin/bash
set -euxo pipefail


loki_ip_address="${1:-10.10.0.2}"


#
# install build dependencies.

apt-get install -y make


#
# clone linuxkit.

git clone https://github.com/linuxkit/linuxkit.git
cd linuxkit
git checkout -f 46d4edc967b5a9de705840d30c83b83fedabb492 # 2021-08-14T12:30:35Z


#
# build linuxkit.

make

# add to PATH.
cat >/etc/profile.d/linuxkit.sh <<EOF
export PATH="\$PATH:$PWD/bin"
EOF
source /etc/profile.d/linuxkit.sh

# show the built binary version.
linuxkit version


#
# build our local pkgs.

for pkg in docker:20.10.8-dind; do
    name="$(echo $pkg | awk -F : '{print $1}')"
    hash="$(echo $pkg | awk -F : '{print $2}')"
    linuxkit pkg build \
        -force \
        -docker \
        -network \
        -platforms linux/amd64,linux/arm64 \
        -org local \
        -hash $hash \
        "/vagrant/pkg/$name"
done


#
# configure linuxkit-example.

sed -E "s,@@loki_push_url@@,http://$loki_ip_address:3100/loki/api/v1/push,g" /vagrant/promtail-config.yml \
    >promtail-config.yml

sed -E "s,@@loki_push_url@@,http://$loki_ip_address:3100/loki/api/v1/push,g" /vagrant/linuxkit-example.yml \
    >linuxkit-example.yml


#
# build linuxkit-example iso (for bios and uefi boot) and kernel+initrd (for pxe boot) images.

linuxkit build -format iso-bios,iso-efi,kernel+initrd -docker linuxkit-example.yml
mv linuxkit-example-efi.iso linuxkit-example-uefi.iso


#
# copy built artefacts to the host, so we can use them from the host or other VMs.

mkdir -p /vagrant/shared
cp -f bin/linuxkit /vagrant/shared
cp -f linuxkit-example* /vagrant/shared


#
# install into the pxe server.

# add the linuxkit-example kernel and initrd matchbox assets.
install -m 644 linuxkit-example-kernel /var/lib/matchbox/assets
install -m 644 linuxkit-example-initrd.img /var/lib/matchbox/assets
python3 /vagrant/modules/pxe_server_register_machines.py
systemctl restart dnsmasq
