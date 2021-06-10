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
git checkout -f 79b32dc2c74a7cd2ef56c834c771b978a5ed16a7 # 2021-06-02T09:34:40Z


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

for pkg in docker:20.10.7-dind; do
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
# build linuxkit-example iso (for bios and efi boot) and kernel+initrd (for pxe boot) images.

linuxkit build -format iso-bios,iso-efi,kernel+initrd -docker linuxkit-example.yml


#
# copy built artefacts to the host, so we can use them from the host or other VMs.

mkdir -p /vagrant/shared
cp -f bin/linuxkit /vagrant/shared
cp -f linuxkit-example* /vagrant/shared
