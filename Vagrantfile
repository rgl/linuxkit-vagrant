config_builder_fqdn = 'builder.lk.example.com'
config_builder_ip   = '10.1.0.2'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-20.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    #lv.cpu_mode = 'host-passthrough'
    #lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.define :builder do |config|
    config.vm.provider :libvirt do |lv|
      lv.memory = 4096
    end
    config.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    config.vm.hostname = config_builder_fqdn
    config.vm.network :private_network, ip: config_builder_ip
    config.vm.provision :shell, path: 'provision-base.sh'
    config.vm.provision :shell, path: 'provision-docker.sh'
    config.vm.provision :shell, path: 'provision-linuxkit.sh'
  end

  ['bios', 'efi'].each do |firmware|
    config.vm.define firmware do |config|
      config.ssh.username = 'root'
      config.ssh.sudo_command = '%c'
      config.vm.guest = 'alpine' # LinuxKit is Alpine based.
      config.vm.box = 'empty'
      config.vm.provider :libvirt do |lv, config|
        lv.loader = '/usr/share/ovmf/OVMF.fd' if firmware == 'efi'
        lv.storage :file, :device => :cdrom, :path => "#{Dir.pwd}/shared/sshd#{firmware == 'bios' && '' || '-'+firmware}.iso"
        lv.boot 'cdrom'
        config.vm.synced_folder '.', '/vagrant', disabled: true
      end
      config.vm.provider :virtualbox do |vb|
        vb.check_guest_additions = false
        vb.functional_vboxsf = false
        vb.customize ['modifyvm', :id, '--firmware', firmware]
        vb.customize ['storageattach', :id,
          '--storagectl', 'SATA Controller',
          '--device', '0',
          '--port', '0',
          '--type', 'dvddrive',
          '--tempeject', 'on',
          '--medium', "shared/sshd#{firmware == 'bios' && '' || '-'+firmware}.iso"]
      end
      # NB we need to modify the upload_path because /tmp is mounted with noexec.
      config.vm.provision 'shell', inline: 'uname -a', upload_path: '/var/tmp/vagrant-shell', name: 'linux version'
      config.vm.provision 'shell', inline: 'ctr version', upload_path: '/var/tmp/vagrant-shell', name: 'containerd version'
    end
  end

  config.trigger.before :up do |trigger|
    trigger.only_on = ['bios', 'efi']
    trigger.run = {path:'./create_empty_box.sh'}
  end
end
