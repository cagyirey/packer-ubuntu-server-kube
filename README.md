# packer-ubuntu-server-kube
Packer and Vagrant templates for simple Kubernetes clusters


## Instructions

```powershell
git clone https://github.com/cagyirey/packer-ubuntu-server-kube.git; cd packer-ubuntu-server-kube
packer build ubuntu-server-hyperv.json
packer box add build/ubuntu-20.04.2-live-server-amd64.hyperv.box --name ubuntu-kube
mkdir -p ~/vagrant_vms/ubuntu_kube; cd ~/vagrant_vms/ubuntu_kube
vagrant init ubuntu-kube
vagrant up
```
