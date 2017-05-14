This is a [Vagrant](https://www.vagrantup.com/) Environment for a playing with [LinuxKit](https://github.com/linuxkit/linuxkit).

# Usage

Build and install the [Ubuntu Base Box](https://github.com/rgl/ubuntu-vagrant).

Install the following Vagrant plugin:

```bash
vagrant plugin install vagrant-triggers # see https://github.com/emyl/vagrant-triggers
```

Run `vagrant up builder` to launch the environment that builds the `shared/sshd.iso` and `sshd-efi.iso` files.

Run `vagrant up bios` to launch `shared/sshd.iso`.

Run `vagrant up efi` to launch `shared/sshd-efi.iso` (**NB** this is somewhat boken because the screen stays blank).
