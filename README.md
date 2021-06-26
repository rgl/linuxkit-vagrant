This is a [Vagrant](https://www.vagrantup.com/) Environment for a playing with [LinuxKit](https://github.com/linuxkit/linuxkit).

# Table Of Contents

* [Usage](#usage)
* [Logs](#logs)
  * [Log Labels](#log-labels)
* [Network Packet Capture](#network-packet-capture)
* [Network Booting](#network-booting)
  * [Tested Physical Machines](#tested-physical-machines)
* [References](#references)

# Usage

Build and install the [Ubuntu Base Box](https://github.com/rgl/ubuntu-vagrant).

Run `vagrant up builder --no-destroy-on-error --no-tty` to launch the environment that builds the `shared/linuxkit-example.iso` and `shared/linuxkit-example-uefi.iso` files.

Run `vagrant up bios-iso --no-destroy-on-error --no-tty` to launch `shared/linuxkit-example.iso`.

Run `vagrant up uefi-iso --no-destroy-on-error --no-tty` to launch `shared/linuxkit-example-uefi.iso`.

Then access a linuxkit instance with, e.g.:

```bash
vagrant ssh bios-iso
```

You can also launch the iso with one of:

```bash
(cd shared && ./linuxkit run qemu -gui -iso linuxkit-example.iso)
(cd shared && ./linuxkit run vbox -gui -iso linuxkit-example.iso)
```

You can also directly launch the kernel and initrd in qemu:

```bash
(cd shared && ./linuxkit run qemu -gui -kernel linuxkit-example)
(cd shared && cp /usr/share/ovmf/OVMF.fd . && ./linuxkit run qemu -gui -uefi -fw ./OVMF.fd -kernel linuxkit-example)
```

You can list the contents of the initramfs with:

```bash
zcat linuxkit-example-initrd.img | cpio --list --numeric-uid-gid --verbose | less
```

You can execute docker containers with:

```bash
# enter the bios machine.
vagrant ssh bios

# verify the dockerd configuration.
cat /hostroot/etc/docker/daemon.json

# open a shell in the docker service.
ctr --namespace services.linuxkit tasks exec --exec-id shell -t docker ash

# execute a docker container.
docker run \
  -d \
  --restart unless-stopped \
  --name hello-docker \
  --label worker_id=123 \
  alpine:3.14 \
    /bin/sh \
    -c \
    'while true; do echo hello docker $(date); sleep 1; done'

# tail the logs.
# NB at the builder machine, you can tail then with:
#     logcli query --tail '{source="hello-docker"}'
docker logs -f hello-docker

# interact with containerd.
export CONTAINERD_ADDRESS=/var/run/docker/containerd/containerd.sock
export CONTAINERD_NAMESPACE=moby
ctr namespaces list
ctr containers list
ctr --namespace plugins.moby containers list
```

## Logs

You can read individual logs at `/var/log` as separate files. These log files are managed by the `logwrite` service.

You can dump (and then follow) all the logs with `logread -F`. This reads the logs from the `memlogd` managed named socket at `/var/run/memlogdq.sock`.

The logs are also sent to the `builder` machine.

You can explore them with Grafana at:

http://10.1.0.2:3000/explore

You can also explore them with `logcli`:

```bash
vagrant ssh builder

# list all series/streams.
logcli series '{}' | sort

# list all labels.
logcli labels -q | sort

# list all sources.
logcli labels -q source | sort

# get all the containerd logs.
# NB you might want to add --forward --limit 1000 to see the logs from
#    oldest to newer.
logcli query '{source="containerd"}'

# tail all the containerd logs.
logcli query --tail '{source="containerd"}'

# raw tail all the containerd logs.
logcli query --tail --output raw '{source="containerd"}'

# tail all sources.
logcli query --tail --limit 1000 '{source=~".+"}'

# tail all sources looking for errors.
logcli query --tail --limit 1000 '{source=~".+"} |~ "error"'
```

### Log Labels

Available log labels:

| Label    | Description                                 |
|----------|---------------------------------------------|
| `host`   | hostname of the host that captured the log  |
| `job`    | name of the collector that captured the log |
| `source` | name of the source that produced the log    |

Available job label instances:

| Job          | Description                                 |
|--------------|---------------------------------------------|
| `containerd` | logs read from containerd log files         |
| `container`  | logs read from each docker container        |
| `logwrite`   | logs read from logwrite generated log files |

Available source label instances:

| Source         | Description                     |
|----------------|---------------------------------|
| `containerd`   | `containerd` service            |
| `dhcpcd`       | `dhcpcd` service                |
| `docker`       | `docker` service                |
| `hello`        | `hello` service                 |
| `hello-docker` | `hello-docker` docker container |
| `kmsg`         | linux kernel                    |
| `memlogd`      | `memlogd` service               |
| `promtail`     | `promtail` service              |
| `rngd`         | `rngd` service                  |
| `rngd1`        | `rngd` onboot service           |
| `sshd`         | `sshd` service                  |

## Network Packet Capture

You can easily capture and see traffic from the host with the `wireshark.sh`
script, e.g., to capture the traffic from the `eth1` interface:

```bash
./wireshark.sh builder eth1
```

## Network Booting

This environment can also PXE/iPXE/UEFI-HTTP boot LinuxKit.

To PXE boot a BIOS Virtual Machine with PXE/TFTP/iPXE/HTTP run:

```bash
vagrant up bios-pxe --no-destroy-on-error --no-tty
```

To PXE boot a UEFI Virtual Machine with PXE/TFTP/iPXE/HTTP run:

```bash
vagrant up uefi-pxe --no-destroy-on-error --no-tty
```

To boot Physical Machines you have to:

* Create a Linux Bridge that can reach a Physical Switch that connects to
  your Physical Machines.
  * This environment assumes you have a setup like [rgl/ansible-collection-tp-link-easy-smart-switch](https://github.com/rgl/ansible-collection-tp-link-easy-smart-switch).
  * To configure it otherwise you must modify the `Vagrantfile`.
* Add your machines to `machines.json`.
* Configure your machines to PXE boot.

### Tested Physical Machines

This was tested on the following physical machines and boot modes:

* [Seeed Studio Odyssey X86J4105](https://github.com/rgl/seeedstudio-odyssey-x86j4105-notes)
  * It boots using [UEFI/HTTP/PXE](https://github.com/rgl/seeedstudio-odyssey-x86j4105-notes/tree/master/network-boot#uefi-http-pxe).
* [HP EliteDesk 800 35W G2 Desktop Mini](https://support.hp.com/us-en/product/hp-elitedesk-800-35w-g2-desktop-mini-pc/7633266)
  * It boots using UEFI/TFTP/PXE.
  * This machine can be remotely managed with [MeshCommander](https://www.meshcommander.com/meshcommander).
    * It was configured as described at [rgl/intel-amt-notes](https://github.com/rgl/intel-amt-notes).

# References

* LinuxKit
  * [Configuration Reference](https://github.com/linuxkit/linuxkit/blob/master/docs/yaml.md)
  * [Logging (memlogd/init/logwrite)](https://github.com/linuxkit/linuxkit/blob/master/docs/logging.md)
* Linux
  * [Kernel Parameters Index](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.rst)
  * [Kernel Parameters List](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt)
  * [Booloader Parameters List (AMD64)](https://www.kernel.org/doc/Documentation/x86/x86_64/boot-options.txt)
* Promtail
  * [Configuring Promtail](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)
  * [Pipelines](https://grafana.com/docs/loki/latest/clients/promtail/pipelines/)
    * [Pipeline Stages](https://grafana.com/docs/loki/latest/clients/promtail/stages/)
  * [Troubleshooting Promtail](https://grafana.com/docs/loki/latest/clients/promtail/troubleshooting/)
* Loki Docker Driver
  * [Configuring the Docker Driver](https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/)
* Loki:
  * [LogQL: Log Query Language](https://grafana.com/docs/loki/latest/logql/)
* iPXE:
  * [Scripting](https://ipxe.org/scripting)
  * [Command reference](https://ipxe.org/cmd)
  * [Settings reference](https://ipxe.org/cfg)
* Matchbox:
  * [PXE-enabled DHCP](https://github.com/poseidon/matchbox/blob/master/docs/network-setup.md#pxe-enabled-dhcp)
  * [Proxy-DHCP](https://github.com/poseidon/matchbox/blob/master/docs/network-setup.md#proxy-dhcp)
* Dynamic Host Configuration Protocol (DHCP):
  * [Parameters / Options](https://www.iana.org/assignments/bootp-dhcp-parameters/bootp-dhcp-parameters.xhtml)
* [Building the Simplest Possible Linux System by Rob Landley](https://www.youtube.com/watch?v=Sk9TatW9ino)
