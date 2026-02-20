resource "proxmox_vm_qemu" "k3s_nodes" {
  count = var.k3s_count

  # Identification
  name        = count.index == 0 ? "k3s-master" : "k3s-worker-${format("%02d", count.index)}"
  target_node = var.proxmox_node
  vmid        = 200 + count.index

  # Template
  clone = var.template_name

  # Ressources CPU/RAM
  memory = var.k3s_vm_memory
  cpu {
    cores   = var.k3s_vm_cores
    sockets = 1
  }

  # SCSI Controller
  scsihw = "virtio-scsi-single"

  # QEMU Guest Agent
  agent = 1

  # Démarrage automatique
  start_at_node_boot = true
  startup_shutdown {
    order = 1
  }

  # Disque
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.storage_pool
    size    = var.k3s_vm_disk_size
    format  = "qcow2"
    cache   = "writeback"
  }

  # CloudInit Drive
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage_pool
  }

  # Cloud-Init
  os_type = "cloud-init"

  # Serial port pour console
  serial {
    id   = 0
    type = "socket"
  }

  # Réseau
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }

  # Cloud-Init - Configuration réseau
  ipconfig0 = "ip=${cidrhost("192.168.1.0/24", 102 + count.index)}/24,gw=${var.network_gateway}"

  nameserver = var.network_dns

  # Cloud-Init - Configuration utilisateur
  ciuser     = var.k3s_vm_user
  cipassword = var.vm_password
  sshkeys    = join("\n", var.ssh_public_keys)


  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}
