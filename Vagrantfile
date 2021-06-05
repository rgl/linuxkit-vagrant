config_builder_fqdn = 'builder.lk.example.com'
config_builder_ip   = '10.1.0.2'

# to make sure the vms are created sequentially, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-20.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.cpus = 2
    #lv.cpu_mode = 'host-passthrough'
    #lv.nested = true
    lv.memory = 2048
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.cpus = 2
    vb.memory = 2048
  end

  config.vm.define :builder do |config|
    config.vm.provider :libvirt do |lv|
      lv.cpus = 4
      lv.memory = 4096
    end
    config.vm.provider :virtualbox do |vb|
      vb.cpus = 4
      vb.memory = 4096
    end
    config.vm.hostname = config_builder_fqdn
    config.vm.network :private_network, ip: config_builder_ip
    config.vm.provision :shell, path: 'provision-base.sh'
    config.vm.provision :shell, path: 'provision-docker.sh'
    config.vm.provision :shell, path: 'provision-loki.sh'
    config.vm.provision :shell, path: 'provision-linuxkit.sh', args: [config_builder_ip]
  end

  ['bios', 'efi'].each do |firmware|
    config.vm.define firmware do |config|
      config.ssh.username = 'root'
      config.ssh.sudo_command = '%c'
      config.vm.guest = 'alpine' # LinuxKit is Alpine based.
      config.vm.box = 'empty'
      config.vm.provider :libvirt do |lv, config|
        lv.loader = '/usr/share/ovmf/OVMF.fd' if firmware == 'efi'
        lv.storage :file, :device => :cdrom, :path => "#{Dir.pwd}/shared/linuxkit-example#{firmware == 'bios' && '' || '-'+firmware}.iso"
        lv.boot 'cdrom'
        lv.management_network_name = 'linuxkit-vagrant0'
        lv.management_network_address = "#{config_builder_ip}/24"
        lv.random :model => 'random'
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
          '--medium', "shared/linuxkit-example#{firmware == 'bios' && '' || '-'+firmware}.iso"]
      end
      # NB we need to modify the upload_path because /tmp is mounted with noexec.
      config.vm.provision 'shell', name: 'show info', upload_path: '/var/tmp/vagrant-shell', inline: '''
        set -euxo pipefail
        uname -a
        ctr version
        ctr namespaces ls
        ctr --namespace services.linuxkit images ls
        ctr --namespace services.linuxkit containers ls
        #ctr --namespace services.linuxkit container info sshd
        ctr --namespace services.linuxkit tasks ls
        '''
    end
  end

  config.trigger.before :up do |trigger|
    trigger.only_on = ['bios', 'efi']
    trigger.run = {path:'./create_empty_box.sh'}
  end
end
