#!/bin/bash
set -euxo pipefail


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
# build linuxkit-example iso (for bios and efi boot) and kernel+initrd (for pxe boot) images.

linuxkit build -format iso-bios,iso-efi,kernel+initrd -docker /vagrant/linuxkit-example.yml


#
# copy built artefacts to the host, so we can use them from the host or other VMs.

mkdir -p /vagrant/shared
cp -f bin/linuxkit /vagrant/shared
cp -f linuxkit-example* /vagrant/shared
