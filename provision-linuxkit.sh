#!/bin/bash
set -euxo pipefail


#
# install build dependencies.

apt-get install -y make


#
# clone linuxkit.

git clone https://github.com/linuxkit/linuxkit.git
cd linuxkit
git checkout -f 6312d580324ee5592dbd026610e1e7897a4aac6b # 2021-05-26T13:27:52Z


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
# build example iso (for bios and efi boot) and kernel+initrd (for pxe boot) images.

cd examples
# add the default vagrant insecure key.
sed -i -E "s,source:.+,contents: \"$(wget -qO- https://raw.github.com/hashicorp/vagrant/master/keys/vagrant.pub)\"," sshd.yml
# build it.
linuxkit build -format iso-bios,iso-efi,kernel+initrd sshd.yml


#
# copy built artefacts to the host, so we can use them from the host or other VMs.

mkdir -p /vagrant/shared
cp ../bin/linuxkit /vagrant/shared
cp sshd* /vagrant/shared
