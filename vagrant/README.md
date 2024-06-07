# Vagrant

## Prerequisites

Please install the following:

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

To install the prerequisites on MacOS with Homebrew:

```bash
brew cask install virtualbox
brew cask install vagrant
```

## Setting up

Before starting the Vagrant machine, check its settings in the [../Vagrantfile](../Vagrantfile),
especially the `vb.cpus` and `vb.memory` settings, to adjust to your host machine.
A safe setting is to set those values to a half of what the host has.

So for example if your host has 8 cores and 16 GB of RAM memory,
these values should be set to `vb.cpus = 4` and `vb.memory = 8192`.

You can set up the Vagrant environment with just one command:

```bash
vagrant up
```

After successfull installation you can ssh to the virtual machine with:

```bash
vagrant ssh
cd /sumologic
```

The `/sumologic` directory in Vagrant is mapped to this repository's root directory on the host.

## Run plugin

To run plugin, you simply need to SSH into the machine and run the following snippet:

```bash
cd /sumologic/vagrant
make run
```
