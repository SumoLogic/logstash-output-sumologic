# -*- mode: ruby -*-
# vi: set ft=ruby :

unless Vagrant.has_plugin?("vagrant-disksize")
  puts "vagrant-disksize plugin unavailable\n" +
       "please install it via 'vagrant plugin install vagrant-disksize'"
  exit 1
end

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/focal64'
  config.disksize.size = '50GB'
  config.vm.box_check_update = false
  config.vm.host_name = 'logstash-output-sumologic'
  config.vm.network :private_network, ip: "192.168.78.14"

  config.vm.provider 'virtualbox' do |vb|
    vb.gui = false
    vb.cpus = 8
    vb.memory = 16384
    vb.name = 'logstash-output-sumologic'
  end

  config.vm.provision 'shell', path: 'vagrant/provision.sh'

  config.vm.synced_folder ".", "/sumologic"
end
