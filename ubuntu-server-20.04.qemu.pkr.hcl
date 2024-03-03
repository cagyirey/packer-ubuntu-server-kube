packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    parallels = {
      version = ">= 1.1.0"
      source  = "github.com/Parallels/parallels"
    }
  }
}

variable "vm_name" {
  type    = string
  default = "ubuntu-2004-uefi-amd64"
}

variable "disk_size" {
  type    = string
  default = "61440M"
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.ubuntu.com/releases/23.10/release/ubuntu-23.10-live-server-arm64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:5ea4c792a0cc5462a975d2f253182e9678cc70172ebd444d730f2c4fd7678e43"
}

variable "efi_bios" {
  type = string
  # Use '/usr/share/ovmf/OVMF.fd' on Ubuntu 20.04
  default = "./efi/OVMF-pure-efi.fd"
}

variable "cpu_cores" {
  type = string
  default = "6"
}


variable "threads_per_core" {
  type = string
  default = "2"
}

variable "bios_boot_command" {
  type = list(string)
  default = [ "<enter><f6><esc><wait>",
    "{{ user `boot_command_prefix` }}",
    "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter>" ]
}
variable "efi_boot_command" {
  type = list(string)
  default = [
    "<esc>",
    "linux /casper/vmlinuz quiet fsck.mode=skip autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---",
    "<enter>initrd /casper/initrd",
    "<enter>boot<enter>" ]
}

source "parallels-iso" "ubuntu-arm64-uefi" {
    iso_url = var.iso_url
    iso_checksum = var.iso_checksum

    disk_size = var.disk_size

    guest_os_type = "ubuntu"
    parallels_tools_flavor = "lin-arm"

    cpus = var.cpu_cores
    memory = var.memory

    prlctl = [
      [ "set", "{{.Name}}", "--memsize", var.memory ],
      [ "set", "{{.Name}}", "--cpus", var.cpu_cores ],
      [ "set", "{{.Name}}", "--efi-boot", "on" ],
      [ "set", "{{.Name}}", "--hypervisor-type", "parallels" ],
      [ "set", "{{.Name}}", "--adaptive-hypervisor", "off" ]
    ]

}

source "qemu" "ubuntu-2004-amd64-uefi" {
    headless        = false
    iso_url         = var.iso_url
    iso_checksum    = var.iso_checksum
    memory          = 4096
    machine_type    = "q35"
    firmware        = "./efi/OVMF-pure-efi.fd"

    disk_interface      = "virtio-scsi"
    disk_discard        = "unmap"
    disk_detect_zeroes  = "unmap"
    format              = "raw"
    disk_size           = var.disk_size

    net_device          = "virtio-net"
    http_directory      = "http/maas"

    qemuargs = [
        # CPU and BIOS configuration
        ["-smp", "cores=${ var.cpu_cores },threads=${ var.threads_per_core }" ],
        ["-drive", "if=pflash,file=${ var.efi_bios },format=raw,unit=0,readonly=on"],
        ["-global", "driver=cfi.pflash01,property=secure,value=on"],
        
        # Hardware Devices
        ["-vga", "virtio"],
        ["-device", "virtio-net,netdev=user.0"],
        ["-device", "usb-tablet"],
        
        # USB Storage
        ["-device", "piix3-usb-uhci"],
        ["-device", "nec-usb-xhci,id=xhci"],
        ["-device", "usb-storage,drive=usb0"],
        ["-drive", "if=none,file=${ var.iso_url },id=usb0,media=cdrom,format=raw,readonly=on,index=0"],

        # Virtio-SCSI Storage
        ["-device", "virtio-scsi-pci,id=scsi0"],
        ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
        ["-drive", "if=none,file={{ .OutputDir }}/{{ .Name }},id=drive0,cache=writeback,discard=unmap,format=qcow2,detect-zeroes=unmap,index=1"],
    ]

    boot_wait           = "10s"
    boot_command        = var.efi_boot_command
    shutdown_command    = "echo ''|sudo -S shutdown -P now"
    communicator        = "ssh"
    ssh_username        = "vagrant"
    ssh_password        = "vagrant"
    ssh_timeout         = "15m"
}

build {

  name = "prl-darwin-arm"

  source "source.parallels-iso.ubuntu-arm64-uefi" { 


  }

  provisioner "breakpoint" {
    disable = false
    note    = "this is a breakpoint"
  }

  post-processors {  
      post-processor "vagrant" {
          keep_input_artifact = true
          provider_override   = "parallels"
          vagrantfile_template = "templates/maas/Vagrantfile"
          compression_level     = 9
      }  
  }
}

build {
    name = "qemu-darwin"

    source "source.qemu.ubuntu-2004-amd64-uefi" {
      accelerator = "hvf"
      display = "cocoa"    
    }
    
    post-processors {  
        post-processor "vagrant" {
            keep_input_artifact = true
            provider_override   = "libvirt"
            vagrantfile_template = "templates/maas/Vagrantfile"
            compression_level     = 9
        }  
    }
}

build {
    name = "qemu-windows"
    source "source.qemu.ubuntu-2004-amd64-uefi" {
      accelerator = "whpx"
    }
    
    post-processors {  
        post-processor "vagrant" {
            keep_input_artifact = true
            provider_override   = "libvirt"
            vagrantfile_template = "templates/maas/Vagrantfile"
            compression_level     = 9
        }  
    }
}

