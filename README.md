This is a [Vagrant](https://www.vagrantup.com/) Environment for a playing with [LinuxKit](https://github.com/linuxkit/linuxkit).

# Usage

Build and install the [Ubuntu Base Box](https://github.com/rgl/ubuntu-vagrant).

Run `vagrant up builder --no-destroy-on-error --no-tty` to launch the environment that builds the `shared/sshd.iso` and `shared/sshd-efi.iso` files.

Run `vagrant up bios --no-destroy-on-error --no-tty` to launch `shared/sshd.iso`.

Run `vagrant up efi --no-destroy-on-error --no-tty` to launch `shared/sshd-efi.iso` (**NB** this is somewhat boken because the screen stays blank).

You can also launch the iso with one of:

```bash
(cd shared && ./linuxkit run qemu -gui -iso sshd.iso)
(cd shared && ./linuxkit run vbox -gui -iso sshd.iso)
```

# References

* [Kernel Parameters Index](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.rst)
* [Kernel Parameters List](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt)
* [Booloader Parameters List (AMD64)](https://www.kernel.org/doc/Documentation/x86/x86_64/boot-options.txt)
* [Building the Simplest Possible Linux System by Rob Landley](https://www.youtube.com/watch?v=Sk9TatW9ino)
