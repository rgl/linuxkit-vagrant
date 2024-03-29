#!/bin/bash
set -euxo pipefail

# install dependencies.
apt-get install --no-install-recommends -y git build-essential liblzma-dev

# clone the ipxe repo.
cd ~
[ -d ipxe ] || git clone https://github.com/ipxe/ipxe.git ipxe
cd ipxe
git fetch origin master
git checkout v1.21.1

# configure.
# see https://ipxe.org/buildcfg/cert_cmd
# see https://ipxe.org/buildcfg/download_proto_https
# see https://ipxe.org/buildcfg/image_trust_cmd
# see https://ipxe.org/buildcfg/neighbour_cmd
# see https://ipxe.org/buildcfg/nslookup_cmd
# see https://ipxe.org/buildcfg/ntp_cmd
# see https://ipxe.org/buildcfg/param_cmd
# see https://ipxe.org/buildcfg/ping_cmd
# see https://ipxe.org/buildcfg/poweroff_cmd
# see https://ipxe.org/buildcfg
# see https://ipxe.org/appnote/named_config
cat >src/config/local/general.h <<'EOF'
#define CERT_CMD                /* Certificate management commands */
#define DOWNLOAD_PROTO_HTTPS    /* Secure Hypertext Transfer Protocol */
#define DOWNLOAD_PROTO_TFTP     /* Trivial File Transfer Protocol */
#define IMAGE_TRUST_CMD         /* Image trust management commands */
#define NEIGHBOUR_CMD           /* Neighbour management commands */
#define NSLOOKUP_CMD            /* Name resolution command */
#define NTP_CMD                 /* Network time protocol commands */
#define PARAM_CMD               /* Form parameter commands */
#define PING_CMD                /* Ping command */
#define POWEROFF_CMD            /* Power off command */
#undef  SANBOOT_PROTO_AOE       /* AoE protocol */
EOF
# see https://ipxe.org/buildcfg/keyboard_map
cat >src/config/local/console.h <<'EOF'
// NB this only works with bios mode (e.g. with undionly.kpxe).
//    has no effect in UEFI mode (somehow, you must set the layout in the
//    UEFI firmware instead).
#undef KEYBOARD_MAP
#define KEYBOARD_MAP pt
EOF

# build.
# see https://ipxe.org/embed
# see https://ipxe.org/scripting
# see https://ipxe.org/cmd
# see https://ipxe.org/cmd/ifconf
# see https://ipxe.org/appnote/buildtargets
NUM_CPUS=$((`getconf _NPROCESSORS_ONLN` + 2))
# NB sometimes, for some reason, when we change the settings at
#    src/config/local/*.h they will not always work unless we
#    build from scratch.
rm -rf src/bin*
# NB if you are having trouble running iPXE you can make a DEBUG build with,
#    e.g.:
#       make ... DEBUG=init
#    see iPXE initialising devices... loop at
#        https://lists.ipxe.org/pipermail/ipxe-devel/2021-June/007464.html
time make -j $NUM_CPUS -C src \
    bin/undionly.kpxe \
    bin-x86_64-efi/ipxe.efi \
    DEBUG=init

# install.
install -m 644 src/bin/undionly.kpxe /srv/pxe
install -m 644 src/bin-x86_64-efi/ipxe.efi /srv/pxe
install -m 644 src/bin/undionly.kpxe /var/lib/matchbox/assets
install -m 644 src/bin-x86_64-efi/ipxe.efi /var/lib/matchbox/assets
