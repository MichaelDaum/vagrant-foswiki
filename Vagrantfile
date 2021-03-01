# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

require 'json'
require_relative 'lib/vagrant'

if !File.exist?("config.yml")
  puts "ERROR: please create a config.yml using the file config.yml.example"
  exit
end

vconfig = load_config([ 
  "config/default.config.yml", 
  "config.yml"
])

host_name = vconfig['host_name'] + '.' + vconfig['domain_name']

foswiki_site_preferences=[]

vconfig['foswiki_site_preferences'].each do |pref|
  pref.each do |key, val|
    foswiki_site_preferences.push("-#{key}", "#{val}")
  end
end

Vagrant.configure("2") do |config|

  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  config.vm.define host_name do |host|
    host.vm.hostname = host_name
    host.vm.box = vconfig['box']
    host.vm.box_check_update = true

    host.vm.synced_folder ".", "/vagrant", disabled: true
    host.vm.boot_timeout = 600

    #host.vm.network "public_network"
    # host.vm.network :private_network, ip: '172.31.172.172'

#   host.vm.provider "virtualbox" do |vb|
#     vb.name = host_name
#     vb.memory = vconfig['memory']
#     vb.cpus = vconfig['cpus']
#   end

    host.vm.network "private_network", 
      :type => "dhcp",
      :network_name => vconfig['domain_name'],
      :libvirt__domain_name => vconfig['domain_name']

    host.vm.provider :libvirt do |libvirt|
      libvirt.memory = vconfig['memory']
      libvirt.cpus = vconfig['cpus']
    end

    host.vm.post_up_message = <<MSG
------------------------------------------------------
Foswiki is up and running at https://#{host_name} 

Please make sure the configuration is matching your needs:

  https://#{host_name}/bin/configure

Shell access is available with:

  vagrant ssh 

or by adding a config to your ssh:

  vagrant ssh-config >> ~/.ssh/config 

------------------------------------------------------
MSG

    host.vm.provision "packages", type: "file", source: "packages", destination: "/tmp/"
    host.vm.provision "prepare", type: "shell", path: "scripts/prepare.sh"
    host.vm.provision "network", type: "shell", path: "scripts/network.sh", args: "#{host_name}"

    # install all os packages
    host.vm.provision "install-packages", type: "shell" do |s|
      s.path = "scripts/install-alpine-packages.sh"
      s.args = vconfig['alpine_packages'] 
    end

    # install all cpan packages
    host.vm.provision "install-cpan-packages", type: "shell" do |s|
      s.path = "scripts/install-cpan-packages.sh"
      s.args = vconfig['cpan_packages'] 
    end

    # generate self-sight ssl certificates
    host.vm.provision "generate-certs", type: "shell" do |s|
      s.path = "scripts/generate-certs.sh"
      s.args = "'#{host_name}'"
    end

    host.vm.provision "configure-postfix", type: "shell" do |s|
      s.path = "scripts/configure-postfix.sh"
      s.args = "'#{host_name}' '#{vconfig['mail_relay_host']}' '#{vconfig['mail_root_alias']}'"
    end

    host.vm.provision "configure-nginx", type: "shell" do |s|
      s.path = "scripts/configure-nginx.sh"
      s.args = "'#{host_name}'"
    end

    # install foswiki from zip
    host.vm.provision "install-foswiki", type: "shell" do |s|
      s.path = "scripts/install-foswiki.sh"
      s.args = "'#{host_name}' '#{vconfig['foswiki_password']}' '#{vconfig['http_proxy']}' '#{vconfig['foswiki_version']}'"
    end

    host.vm.provision "install-cronjobs", type: "shell", path: "scripts/install-cronjobs.sh"

    # install all foswiki packages
    host.vm.provision "install-foswiki-packages", type: "shell" do |s|
      s.path = "scripts/install-foswiki-packages.sh"
      s.args = vconfig['foswiki_packages']
    end

    host.vm.provision "install-foswiki-service", type: "shell", path: "scripts/install-foswiki-service.sh"

    host.vm.provision "configure-fail2ban", type: "shell" do |s|
      s.path = "scripts/configure-fail2ban.sh"
    end

    # execute custom provision scripts as per config.yaml
    vconfig['provision'].each do |script|
      host.vm.provision "shell", path: script
    end

    # set the site preferences
    host.vm.provision "configure-site-preferences", type: "shell" do |s|
      s.path = "scripts/configure-site-preferences.sh"
      s.args = foswiki_site_preferences
    end

    # clean up downloads and temp files
    # host.vm.provision "cleanup", type: "shell", path: "scripts/cleanup.sh"
  end

end
