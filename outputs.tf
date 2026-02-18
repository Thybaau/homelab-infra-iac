# === Outputs VMs K3s ===
output "k3s_vms" {
  description = "Informations des VMs K3s"
  value = {
    for vm in proxmox_vm_qemu.k3s_nodes : vm.name => {
      name       = vm.name
      vmid       = vm.vmid
      ip_address = vm.default_ipv4_address
      memory     = vm.memory
      cores      = var.k3s_vm_cores
      disk_size  = var.k3s_vm_disk_size
    }
  }
}

output "k3s_ips" {
  description = "Liste des IPs des VMs K3s"
  value       = [for vm in proxmox_vm_qemu.k3s_nodes : vm.default_ipv4_address]
}

# === Outputs VM OpenClaw ===
output "openclaw_vm" {
  description = "Informations de la VM OpenClaw"
  value = {
    name       = proxmox_vm_qemu.openclaw.name
    vmid       = proxmox_vm_qemu.openclaw.vmid
    ip_address = proxmox_vm_qemu.openclaw.default_ipv4_address
    memory     = proxmox_vm_qemu.openclaw.memory
    cores      = var.openclaw_vm_cores
    disk_size  = var.openclaw_vm_disk_size
  }
}

# === Output Global ===
output "all_vms_summary" {
  description = "Résumé de toutes les VMs déployées"
  value = {
    total_vms    = var.k3s_count + 1
    total_memory = (var.k3s_vm_memory * var.k3s_count) + var.openclaw_vm_memory
    total_cores  = (var.k3s_vm_cores * var.k3s_count) + var.openclaw_vm_cores
    storage_pool = var.storage_pool
    network      = var.network_bridge
  }
}
