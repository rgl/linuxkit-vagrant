CONFIG_BUILDER_IP = '10.10.0.2'
CONFIG_BUILDER_DHCP_RANGE = '10.10.0.100,10.10.0.200,10m'

# do not connect the builder to a external network tru the given bridge.
CONFIG_BUILDER_EXTERNAL_IP = nil
CONFIG_BUILDER_BRIDGE_NAME = nil
CONFIG_BUILDER_EXTERNAL_DHCP_RANGE = nil

# connect the builder to a external network tru the given bridge.
# NB comment this block when not required.
CONFIG_BUILDER_BRIDGE_NAME = 'br-rpi'
CONFIG_BUILDER_EXTERNAL_IP = '10.3.0.2'
CONFIG_BUILDER_EXTERNAL_DHCP_RANGE = '10.3.0.100,10.3.0.200,10m'

# this environment libvirt network name.
CONFIG_NETWORK_NAME = "#{File.basename(File.dirname(__FILE__))}0"

# to make sure the vms are created sequentially, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

def virtual_machines
  return [] unless File.exists? 'shared/machines.json'
  machines = JSON.load(File.read('shared/machines.json')).select{|m| m['type'] == 'virtual'}
  machines.each_with_index.map do |m, i|
    (firmware, boot) = m['name'].split('-')
    [m['name'], firmware, boot, m['ip'], m['mac']]
  end
end

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-20.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.cpus = 2
    #lv.cpu_mode = 'host-passthrough'
    #lv.nested = true
    lv.memory = 2*1024
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: '4.2', nfs_udp: false
  end

  config.vm.define :builder do |config|
    config.vm.provider :libvirt do |lv|
      lv.cpus = 4
      lv.memory = 4*1024
    end
    config.vm.hostname = 'builder.test'
    config.vm.network :private_network,
      ip: CONFIG_BUILDER_IP,
      libvirt__dhcp_enabled: false,
      libvirt__forward_mode: 'none'
    if CONFIG_BUILDER_BRIDGE_NAME
      config.vm.network :public_network,
        ip: CONFIG_BUILDER_EXTERNAL_IP,
        dev: CONFIG_BUILDER_BRIDGE_NAME,
        mode: 'bridge',
        type: 'bridge'
    end
    config.vm.provision :shell, path: 'provision-base.sh'
    config.vm.provision :shell, path: 'provision-iptables.sh'
    config.vm.provision :shell, path: 'provision-docker.sh'
    config.vm.provision :shell, path: 'provision-meshcommander.sh'
    config.vm.provision :shell, path: 'provision-loki.sh'
    config.vm.provision :shell, path: 'provision-grafana.sh', args: [CONFIG_BUILDER_IP]
    config.vm.provision :shell, path: 'provision-pxe-server.sh', args: [CONFIG_BUILDER_IP, CONFIG_BUILDER_DHCP_RANGE, CONFIG_BUILDER_EXTERNAL_IP, CONFIG_BUILDER_EXTERNAL_DHCP_RANGE]
    config.vm.provision :shell, path: 'provision-ipxe.sh', args: [CONFIG_BUILDER_IP]
    config.vm.provision :shell, path: 'provision-machinator.sh'
    config.vm.provision :shell, path: 'provision-linuxkit.sh', args: [CONFIG_BUILDER_IP]
    config.vm.provision :shell, path: 'summary.sh', run: 'always'
  end

  virtual_machines.each do |name, firmware, boot, ip, mac|
    config.vm.define name do |config|
      config.ssh.username = 'root'
      config.ssh.sudo_command = '%c'
      config.vm.guest = 'alpine' # LinuxKit is Alpine based.
      config.vm.box = 'empty'

      config.vm.provider :libvirt do |lv, config|
        config.vm.box = nil
        lv.loader = '/usr/share/ovmf/OVMF.fd' if firmware == 'uefi'
        if boot == 'iso'
          lv.storage :file, :device => :cdrom, :path => "#{Dir.pwd}/shared/linuxkit-example#{firmware == 'bios' && '' || '-'+firmware}.iso"
          lv.boot 'cdrom'
        else
          lv.boot 'network'
        end
        lv.management_network_name = CONFIG_NETWORK_NAME
        lv.management_network_mac = mac
        lv.management_network_address = "#{CONFIG_BUILDER_IP}/24"
        lv.graphics_type = 'spice'
        lv.video_type = 'virtio'
        # set some BIOS settings that will help us identify this particular machine.
        #
        #   QEMU                | Linux
        #   --------------------+----------------------------------------------
        #   type=1,manufacturer | /sys/devices/virtual/dmi/id/sys_vendor
        #   type=1,product      | /sys/devices/virtual/dmi/id/product_name
        #   type=1,version      | /sys/devices/virtual/dmi/id/product_version
        #   type=1,serial       | /sys/devices/virtual/dmi/id/product_serial
        #   type=1,sku          | dmidecode
        #   type=1,uuid         | /sys/devices/virtual/dmi/id/product_uuid
        #   type=3,manufacturer | /sys/devices/virtual/dmi/id/chassis_vendor
        #   type=3,family       | /sys/devices/virtual/dmi/id/chassis_type
        #   type=3,version      | /sys/devices/virtual/dmi/id/chassis_version
        #   type=3,serial       | /sys/devices/virtual/dmi/id/chassis_serial
        #   type=3,asset        | /sys/devices/virtual/dmi/id/chassis_asset_tag
        [
          'type=1,manufacturer=your vendor name here',
          'type=1,product=your product name here',
          'type=1,version=your product version here',
          'type=1,serial=your product serial number here',
          'type=1,sku=your product SKU here',
          "type=1,uuid=00000000-0000-4000-8000-#{mac.tr(':', '')}",
          'type=3,manufacturer=your chassis vendor name here',
          #'type=3,family=1', # TODO why this does not work on qemu from ubuntu 18.04?
          'type=3,version=your chassis version here',
          'type=3,serial=your chassis serial number here',
          "type=3,asset=your chassis asset tag here #{name}",
        ].each do |value|
          lv.qemuargs :value => '-smbios'
          lv.qemuargs :value => value
        end
        config.vm.synced_folder '.', '/vagrant', disabled: true
      end
    end
  end

  config.trigger.before :up do |trigger|
    trigger.only_on = ['builder']
    trigger.run = {path:'./vagrant-trigger-before-up.sh'}
  end
end
