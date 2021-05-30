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

You can see the logs at `/var/log`.

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
```

# References

* [Kernel Parameters Index](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.rst)
* [Kernel Parameters List](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt)
* [Booloader Parameters List (AMD64)](https://www.kernel.org/doc/Documentation/x86/x86_64/boot-options.txt)
* [Building the Simplest Possible Linux System by Rob Landley](https://www.youtube.com/watch?v=Sk9TatW9ino)
