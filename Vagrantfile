config_builder_fqdn = 'builder.lk.example.com'
config_builder_ip   = '10.1.0.2'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-18.04-amd64'

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
    config.vm.provision :shell, path: 'provision.sh'
  end

  ['bios', 'efi'].each do |firmware|
    config.vm.define firmware do |config|
      config.ssh.username = 'root'
      config.ssh.shell = '/bin/sh' # LinuxKit Alpine uses BusyBox ash instead of bash.
      config.vm.box = 'empty'
      config.vm.synced_folder '.', '/vagrant', disabled: true
      config.vm.provider :libvirt do |lv|
        lv.storage :file, :device => :cdrom, :path => "#{Dir.pwd}/shared/sshd#{firmware == 'bios' && '' || '-'+firmware}.iso"
        lv.boot 'cdrom'
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
    end
  end

  config.trigger.before :up do |trigger|
    trigger.only_on = ['bios', 'efi']
    trigger.run = {path:'./create_empty_box.sh'}
  end
end
