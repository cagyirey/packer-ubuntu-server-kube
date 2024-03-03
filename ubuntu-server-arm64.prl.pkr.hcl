packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
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
  default = "ubuntu-arm64"
}

variable "disk_size" {
  type    = number
  default = 61440
}

variable "memory" {
  type = number
  default = 8096
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

variable "cpus" {
  type = string
  default = "6"
}

variable "efi_boot_command" {
  type = list(string)
  default = [
    "c",
    "linux /casper/vmlinuz quiet fsck.mode=skip autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---",
    "<enter>initrd /casper/initrd",
    "<enter>boot<enter>" ]
}

source "parallels-iso" "ubuntu-arm64-uefi" {

    iso_url       = var.iso_url
    iso_checksum  = var.iso_checksum

    cpus          = var.cpus
    memory        = var.memory
    disk_size     = var.disk_size

    guest_os_type         = "ubuntu"
    parallels_tools_flavor = "lin-arm"

    ssh_username        = "ubuntu"
    ssh_private_key_file = "~/.ssh/gh_personal_ed25519"
    ssh_timeout         = "10m"

    http_directory = "http/ubuntu-server-arm64"

    boot_wait           = "3s"
    boot_command        = var.efi_boot_command
    shutdown_command    = "echo ''|sudo -S shutdown -P now"

    prlctl = [
      [ "set", "{{.Name}}", "--memsize", var.memory ],
      [ "set", "{{.Name}}", "--cpus", var.cpus ],
      [ "set", "{{.Name}}", "--efi-boot", "on" ],
      [ "set", "{{.Name}}", "--hypervisor-type", "apple" ],
      [ "set", "{{.Name}}", "--adaptive-hypervisor", "off" ]
    ]
}

build {
  name = "prl-darwin-arm64"
  source "source.parallels-iso.ubuntu-arm64-uefi" { 

  }
    post-processors {  
        post-processor "vagrant" {
            keep_input_artifact = false
            provider_override   = "parallels"
            vagrantfile_template = "templates/ubuntu-server-arm64/Vagrantfile"
            compression_level   = 9
        }  
    }

}
