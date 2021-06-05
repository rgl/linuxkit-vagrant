This is a [Vagrant](https://www.vagrantup.com/) Environment for a playing with [LinuxKit](https://github.com/linuxkit/linuxkit).

# Usage

Build and install the [Ubuntu Base Box](https://github.com/rgl/ubuntu-vagrant).

Run `vagrant up builder --no-destroy-on-error --no-tty` to launch the environment that builds the `shared/linuxkit-example.iso` and `shared/linuxkit-example-efi.iso` files.

Run `vagrant up bios --no-destroy-on-error --no-tty` to launch `shared/linuxkit-example.iso`.

Run `vagrant up efi --no-destroy-on-error --no-tty` to launch `shared/linuxkit-example-efi.iso` (**NB** this is somewhat boken because the screen stays blank).

Then access it with, e.g.:

```bash
vagrant ssh bios
```

You can read individual logs at `/var/log` as separate files. These log files are managed by the `logwrite` service.

You can dump (and then follow) all the logs with `logread -F`. This reads the logs from the `memlogd` managed named socket at `/var/run/memlogdq.sock`.

The logs are also sent to the `builder` machine, and you can explore them with `logcli`:

```bash
vagrant ssh builder

# list all series/streams.
logcli series '{}'

# list all labels.
logcli labels -q

# list all sources.
logcli labels -q source

# get all the containerd logs.
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
* Loki:
  * [LogQL: Log Query Language](https://grafana.com/docs/loki/latest/logql/)
* [Building the Simplest Possible Linux System by Rob Landley](https://www.youtube.com/watch?v=Sk9TatW9ino)
