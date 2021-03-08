# vagrant-foswiki
A VM to install Foswiki

This setup will allow you to create a virtual image running Foswiki as quick as possible. It contains

- alpine linux
- Foswiki
- postfix
- nginx
- fail2ban

All required perl packages are installed with it. Those perl packages not covered by the linux distrubution are compiled as required via cpan.

Installing vagrant and libvirt:

``
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-add-repository ppa:jacob/virtualisation
apt install vagrant
apt install qemu-kvm libvirt-daemon-system libvirt-clients virtinst cpu-checker libguestfs-tools libosinfo-bin libvirt-dev build-essential
``

Add your user to the libvirt and kvm group

``
adduser <NAME> libvirt
adduser <NAME> kvm
``

Install the libvirt plugin for vagrant

``
vagrant plugin install vagrant-libvirt
``

Copy the example configuration and modify it to your needs:

``
cp config.yml.example config.yml
``

Start the build process:

``
vagrant up
``

