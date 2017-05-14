config_builder_fqdn = 'builder.lk.example.com'
config_builder_ip   = '10.1.0.2'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-16.04-amd64'

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 2048
  end

  config.vm.define :builder do |config|
    config.vm.hostname = config_builder_fqdn
    config.vm.network :private_network, ip: config_builder_ip
    config.vm.provision :shell, path: 'provision.sh'
  end

  ['bios', 'efi'].each do |firmware|
    config.ssh.username = 'root'
    config.ssh.shell = '/bin/sh' # LinuxKit Alpine uses BusyBox ash instead of bash.
    config.vm.define firmware do |config|
      config.vm.box = 'empty'
      config.vm.synced_folder '.', '/vagrant', disabled: true
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

  config.trigger.before :up, :vm => ['bios', 'efi'] do
    run './create_empty_box.sh'
  end
end
