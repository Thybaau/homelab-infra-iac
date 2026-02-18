# ============================================================================
# Variables Terraform pour Infrastructure Proxmox VE
# ============================================================================

# === Authentification Proxmox ===

variable "proxmox_api_url" {
  type        = string
  description = "URL de l'API Proxmox (ex: https://192.168.1.200:8006/api2/json)"
  sensitive   = false
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Token ID Proxmox pour l'authentification API (ex: terraform@pam!terraform)"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Secret du token Proxmox pour l'authentification API"
  sensitive   = true
}

# === Configuration Proxmox ===

variable "proxmox_node" {
  type        = string
  description = "Nom du nœud Proxmox sur lequel déployer les VMs"
  default     = "pve"
}

variable "storage_pool" {
  type        = string
  description = "Pool de stockage Proxmox pour les disques des VMs"
  default     = "ssd-vms"
}

# === Configuration Réseau ===

variable "network_bridge" {
  type        = string
  description = "Bridge réseau Proxmox pour connecter les VMs"
  default     = "vmbr0"
}

variable "network_gateway" {
  type        = string
  description = "Passerelle par défaut pour les VMs"
  default     = "192.168.1.1"
}

variable "network_dns" {
  type        = string
  description = "Serveur DNS pour les VMs"
  default     = "1.1.1.1"
}

variable "network_subnet_mask" {
  type        = string
  description = "Masque de sous-réseau pour les VMs"
  default     = "255.255.255.0"
}

# === Configuration VMs K3s ===

variable "k3s_count" {
  type        = number
  description = "Nombre de VMs K3s à créer pour le cluster"
  default     = 2
}

variable "k3s_vm_memory" {
  type        = number
  description = "Quantité de RAM allouée à chaque VM K3s en Mo"
  default     = 4096
}

variable "k3s_vm_cores" {
  type        = number
  description = "Nombre de vCPUs alloués à chaque VM K3s"
  default     = 2
}

variable "k3s_vm_disk_size" {
  type        = string
  description = "Taille du disque pour chaque VM K3s (ex: 32G)"
  default     = "32G"
}

variable "k3s_vm_ip_start" {
  type        = string
  description = "Adresse IP de départ pour les VMs K3s (les IPs suivantes seront séquentielles)"
  default     = "192.168.1.102"
}

# === Configuration VM OpenClaw ===

variable "openclaw_vm_memory" {
  type        = number
  description = "Quantité de RAM allouée à la VM OpenClaw en Mo"
  default     = 4096
}

variable "openclaw_vm_cores" {
  type        = number
  description = "Nombre de vCPUs alloués à la VM OpenClaw"
  default     = 2
}

variable "openclaw_vm_disk_size" {
  type        = string
  description = "Taille du disque pour la VM OpenClaw (ex: 40G)"
  default     = "40G"
}

variable "openclaw_vm_ip" {
  type        = string
  description = "Adresse IP statique pour la VM OpenClaw"
  default     = "192.168.1.104"
}

# === Configuration Cloud-Init ===

variable "ssh_public_keys" {
  type        = string
  description = "Clés SSH publiques pour l'accès aux VMs (une par ligne, seront injectées via Cloud-Init)"
  sensitive   = false
}

variable "k3s_vm_user" {
  type        = string
  description = "Nom d'utilisateur admin créé sur les VMs K3s via Cloud-Init"
  default     = "k3s"
}

variable "openclaw_vm_user" {
  type        = string
  description = "Nom d'utilisateur admin créé sur la VM OpenClaw via Cloud-Init"
  default     = "admin"
}

variable "template_name" {
  type        = string
  description = "Nom du template Ubuntu Cloud-Init dans Proxmox à cloner pour les VMs"
  default     = "ubuntu-2204-cloudinit"
}
