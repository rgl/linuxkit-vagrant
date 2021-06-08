This is a [Vagrant](https://www.vagrantup.com/) Environment for a playing with [LinuxKit](https://github.com/linuxkit/linuxkit).

# Usage

Build and install the [Ubuntu Base Box](https://github.com/rgl/ubuntu-vagrant).

Run `vagrant up builder --no-destroy-on-error --no-tty` to launch the environment that builds the `shared/linuxkit-example.iso` and `shared/linuxkit-example-efi.iso` files.

Run `vagrant up bios --no-destroy-on-error --no-tty` to launch `shared/linuxkit-example.iso`.

Run `vagrant up efi --no-destroy-on-error --no-tty` to launch `shared/linuxkit-example-efi.iso` (**NB** this is somewhat boken because the screen stays blank).

Then access a linuxkit instance with, e.g.:

```bash
vagrant ssh bios
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
  alpine:3.13 \
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
* [Building the Simplest Possible Linux System by Rob Landley](https://www.youtube.com/watch?v=Sk9TatW9ino)
