resource "proxmox_vm_qemu" "openclaw" {
  # Identification
  name        = "openclaw-01"
  target_node = var.proxmox_node
  vmid        = 210

  # Template
  clone = var.template_name

  # Ressources
  memory = var.openclaw_vm_memory
  cpu {
    cores   = var.openclaw_vm_cores
    sockets = 1
  }

  # Démarrage automatique
  start_at_node_boot = true
  startup_shutdown {
    order = 2
  }

  # Disque
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.storage_pool
    size    = var.openclaw_vm_disk_size
    format  = "qcow2"
    cache   = "writeback"
  }

  # Cloud-Init
  os_type = "cloud-init"

  # Réseau
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }

  # Cloud-Init - Configuration réseau
  ipconfig0 = "ip=${var.openclaw_vm_ip}/24,gw=${var.network_gateway}"

  nameserver = var.network_dns

  # Cloud-Init - Configuration utilisateur
  ciuser  = var.openclaw_vm_user
  sshkeys = var.ssh_public_keys

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}
