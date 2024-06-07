# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/focal64'
  config.vm.disk :disk, size: "50GB", primary: true
  config.vm.box_check_update = false
  config.vm.host_name = 'logstash-output-sumologic'
  # Vbox 6.1.28+ restricts host-only adapters to 192.168.56.0/21
  # See: https://www.virtualbox.org/manual/ch06.html#network_hostonly
  config.vm.network :private_network, ip: "192.168.56.5"

  config.vm.provider 'virtualbox' do |vb|
    vb.gui = false
    vb.cpus = 8
    vb.memory = 16384
    vb.name = 'logstash-output-sumologic'
  end

  config.vm.provider "qemu" do |qe, override|
    override.vm.box = "perk/ubuntu-2204-arm64"
    qe.gui = false
    qe.smp = 8
    qe.memory = 16384
    qe.name = 'logstash-output-sumologic'
  end

  config.vm.provision 'shell', path: 'vagrant/provision.sh', privileged: false

  config.vm.synced_folder ".", "/sumologic"
end
