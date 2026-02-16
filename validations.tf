# ===================================================================
# Validations des Contraintes Matérielles
# ===================================================================
# Ce fichier contient les validations pour garantir que la configuration
# respecte les contraintes matérielles du homelab (RAM, stockage, réseau)

# === Validation 1: RAM Totale ===
# Vérifie que l'allocation totale de RAM ne dépasse pas 12 Go (14 Go - 2 Go marge)
locals {
  total_ram_mb = (var.k3s_vm_memory * var.k3s_count) + var.openclaw_vm_memory
  max_ram_mb   = 12288 # 12 Go maximum (14 Go disponibles - 2 Go marge sécurité)
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
        - VMs K3s: ${var.k3s_count} x ${var.k3s_vm_memory} Mo = ${var.k3s_count * var.k3s_vm_memory} Mo
        - VM OpenClaw: ${var.openclaw_vm_memory} Mo
        
        Solutions possibles:
        1. Réduire k3s_vm_memory (actuellement ${var.k3s_vm_memory} Mo)
        2. Réduire openclaw_vm_memory (actuellement ${var.openclaw_vm_memory} Mo)
        3. Réduire k3s_count (actuellement ${var.k3s_count})
      EOT
    }
  }
}

# === Validation 2: Stockage Total ===
# Vérifie que l'allocation totale de stockage ne dépasse pas 105 Go (125 Go - 20 Go marge)
locals {
  # Extraction de la taille en Go depuis les variables (format "32G" -> 32)
  k3s_disk_gb      = tonumber(regex("(\\d+)", var.k3s_vm_disk_size)[0])
  openclaw_disk_gb = tonumber(regex("(\\d+)", var.openclaw_vm_disk_size)[0])

  total_disk_gb = (local.k3s_disk_gb * var.k3s_count) + local.openclaw_disk_gb
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
        - VM OpenClaw: ${local.openclaw_disk_gb} Go
        
        Solutions possibles:
        1. Réduire k3s_vm_disk_size (actuellement ${var.k3s_vm_disk_size})
        2. Réduire openclaw_vm_disk_size (actuellement ${var.openclaw_vm_disk_size})
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
  openclaw_ip_last_octet  = tonumber(split(".", var.openclaw_vm_ip)[3])

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

resource "null_resource" "validate_openclaw_ip_range" {
  lifecycle {
    precondition {
      condition     = local.openclaw_ip_last_octet >= local.min_ip_last_octet
      error_message = <<-EOT
        ❌ ERREUR: IP OpenClaw dans la plage DHCP!
        
        IP OpenClaw: ${var.openclaw_vm_ip}
        Dernier octet: ${local.openclaw_ip_last_octet}
        Minimum requis: ${local.min_ip_last_octet}
        
        La plage DHCP est 192.168.1.1 à 192.168.1.101.
        Les VMs doivent utiliser des IPs >= 192.168.1.102 pour éviter les conflits.
        
        Solution: Définir openclaw_vm_ip >= 192.168.1.102
      EOT
    }
  }
}
