# ===================================================================
# Validations des Contraintes Matérielles
# ===================================================================
# Ce fichier contient les validations pour garantir que la configuration
# respecte les contraintes matérielles du homelab (RAM, stockage, réseau)

# === Validation 1: RAM Totale ===
# Vérifie que l'allocation totale de RAM ne dépasse pas 14 Go (16 Go - 2 Go marge)
locals {
  total_ram_mb = var.k3s_master_memory + (var.k3s_worker_memory * (var.k3s_count - 1)) + var.jarod_vm_memory
  max_ram_mb   = 14336 # 14 Go maximum (16 Go disponibles - 2 Go marge sécurité)
}

resource "null_resource" "validate_ram" {
  lifecycle {
    precondition {
      condition     = local.total_ram_mb <= local.max_ram_mb
      error_message = <<-EOT
        ❌ ERREUR: Allocation RAM totale excessive!
        
        RAM totale demandée: ${local.total_ram_mb} Mo (${local.total_ram_mb / 1024} Go)
        RAM maximum autorisée: ${local.max_ram_mb} Mo (${local.max_ram_mb / 1024} Go)
        Dépassement: ${local.total_ram_mb - local.max_ram_mb} Mo
        
        Configuration actuelle:
        - VM K3s master: ${var.k3s_master_memory} Mo
        - VMs K3s worker: ${var.k3s_count - 1} x ${var.k3s_worker_memory} Mo = ${(var.k3s_count - 1) * var.k3s_worker_memory} Mo
        - VM JAROD: ${var.jarod_vm_memory} Mo
        
        Solutions possibles:
        1. Réduire k3s_master_memory (actuellement ${var.k3s_master_memory} Mo)
        2. Réduire k3s_worker_memory (actuellement ${var.k3s_worker_memory} Mo)
        3. Réduire jarod_vm_memory (actuellement ${var.jarod_vm_memory} Mo)
        4. Réduire k3s_count (actuellement ${var.k3s_count})
      EOT
    }
  }
}

# === Validation 2: Stockage Total ===
# Vérifie que l'allocation totale de stockage ne dépasse pas 105 Go (125 Go - 20 Go marge)
locals {
  # Extraction de la taille en Go depuis les variables (format "32G" -> 32)
  k3s_disk_gb   = tonumber(regex("(\\d+)", var.k3s_vm_disk_size)[0])
  jarod_disk_gb = tonumber(regex("(\\d+)", var.jarod_vm_disk_size)[0])

  total_disk_gb = (local.k3s_disk_gb * var.k3s_count) + local.jarod_disk_gb
  max_disk_gb   = 105 # 125 Go disponibles - 20 Go marge sécurité
}

resource "null_resource" "validate_storage" {
  lifecycle {
    precondition {
      condition     = local.total_disk_gb <= local.max_disk_gb
      error_message = <<-EOT
        ❌ ERREUR: Allocation stockage totale excessive!
        
        Stockage total demandé: ${local.total_disk_gb} Go
        Stockage maximum autorisé: ${local.max_disk_gb} Go
        Dépassement: ${local.total_disk_gb - local.max_disk_gb} Go
        
        Configuration actuelle:
        - VMs K3s: ${var.k3s_count} x ${local.k3s_disk_gb} Go = ${var.k3s_count * local.k3s_disk_gb} Go
        - VM JAROD: ${local.jarod_disk_gb} Go
        
        Solutions possibles:
        1. Réduire k3s_vm_disk_size (actuellement ${var.k3s_vm_disk_size})
        2. Réduire jarod_vm_disk_size (actuellement ${var.jarod_vm_disk_size})
        3. Réduire k3s_count (actuellement ${var.k3s_count})
      EOT
    }
  }
}

# === Validation 3: Plages IP ===
# Vérifie que les IPs sont hors de la plage DHCP (>= 192.168.1.102)
locals {
  # Extraction du dernier octet des IPs
  k3s_ip_start_last_octet = tonumber(split(".", var.k3s_vm_ip_start)[3])
  jarod_ip_last_octet     = tonumber(split(".", var.jarod_vm_ip)[3])

  min_ip_last_octet = 102 # Première IP valide hors plage DHCP
}

resource "null_resource" "validate_k3s_ip_range" {
  lifecycle {
    precondition {
      condition     = local.k3s_ip_start_last_octet >= local.min_ip_last_octet
      error_message = <<-EOT
        ❌ ERREUR: IP de départ K3s dans la plage DHCP!
        
        IP de départ K3s: ${var.k3s_vm_ip_start}
        Dernier octet: ${local.k3s_ip_start_last_octet}
        Minimum requis: ${local.min_ip_last_octet}
        
        La plage DHCP est 192.168.1.1 à 192.168.1.101.
        Les VMs doivent utiliser des IPs >= 192.168.1.102 pour éviter les conflits.
        
        Solution: Définir k3s_vm_ip_start >= 192.168.1.102
      EOT
    }
  }
}

resource "null_resource" "validate_jarod_ip_range" {
  lifecycle {
    precondition {
      condition     = local.jarod_ip_last_octet >= local.min_ip_last_octet
      error_message = <<-EOT
        ❌ ERREUR: IP JAROD dans la plage DHCP!
        
        IP JAROD: ${var.jarod_vm_ip}
        Dernier octet: ${local.jarod_ip_last_octet}
        Minimum requis: ${local.min_ip_last_octet}
        
        La plage DHCP est 192.168.1.1 à 192.168.1.101.
        Les VMs doivent utiliser des IPs >= 192.168.1.102 pour éviter les conflits.
        
        Solution: Définir jarod_vm_ip >= 192.168.1.102
      EOT
    }
  }
}
