# 📖 Référence Terraform

Documentation des variables, outputs et utilisation locale de Terraform.

- [🔧 Variables](#-variables)
- [📤 Outputs](#-outputs)
- [💻 Utilisation locale](#-utilisation-locale)
- [💾 Backend Terraform local](#-backend-terraform-local)

## 🔧 Variables

Toutes les variables sont configurables pour adapter l'infrastructure à vos besoins.

### Variables d'authentification Proxmox

| Variable | Type | Description | Requis |
|----------|------|-------------|--------|
| `proxmox_api_url` | string | URL de l'API Proxmox | ✅ |
| `proxmox_api_token_id` | string | Token ID Proxmox (sensitive) | ✅ |
| `proxmox_api_token_secret` | string | Secret du token Proxmox (sensitive) | ✅ |

### Variables de configuration Proxmox

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `proxmox_node` | string | `"pve"` | Nom du nœud Proxmox |
| `storage_pool` | string | `"ssd-vms"` | Pool de stockage pour les VMs |

### Variables de configuration réseau

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `network_bridge` | string | `"vmbr0"` | Bridge réseau Proxmox |
| `network_gateway` | string | `"192.168.1.1"` | Passerelle par défaut |
| `network_dns` | string | `"1.1.1.1"` | Serveur DNS |
| `network_subnet_mask` | string | `"255.255.255.0"` | Masque de sous-réseau |

### Variables pour les VMs K3s

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `k3s_count` | number | `2` | Nombre de VMs K3s |
| `k3s_vm_memory` | number | `4096` | RAM par VM K3s (Mo) |
| `k3s_vm_cores` | number | `2` | Nombre de vCPUs par VM K3s |
| `k3s_vm_disk_size` | string | `"32G"` | Taille du disque par VM K3s |
| `k3s_vm_ip_start` | string | `"192.168.1.102"` | IP de départ pour les VMs K3s |

### Variables pour la VM OpenClaw

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `openclaw_vm_memory` | number | `4096` | RAM VM OpenClaw (Mo) |
| `openclaw_vm_cores` | number | `2` | Nombre de vCPUs VM OpenClaw |
| `openclaw_vm_disk_size` | string | `"40G"` | Taille du disque VM OpenClaw |
| `openclaw_vm_ip` | string | `"192.168.1.104"` | IP statique VM OpenClaw |

### Variables Cloud-Init

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `ssh_public_keys` | list(string) | `[]` | Liste des clés SSH publiques pour l'accès aux VMs |
| `k3s_vm_user` | string | `"k3s"` | Utilisateur admin des VMs K3s |
| `openclaw_vm_user` | string | `"admin"` | Utilisateur admin de la VM OpenClaw |
| `template_name` | string | `"ubuntu-22.04-cloudimg"` | Nom du template Ubuntu dans Proxmox |

## 📤 Outputs

Après un déploiement réussi, Terraform affiche les informations suivantes :

### `k3s_vms`

Informations détaillées des VMs K3s :

```json
{
  "k3s-node-01": {
    "vmid": 200,
    "ip_address": "192.168.1.102",
    "memory": 4096,
    "cores": 2,
    "disk_size": "32G"
  },
  "k3s-node-02": {
    "vmid": 201,
    "ip_address": "192.168.1.103",
    "memory": 4096,
    "cores": 2,
    "disk_size": "32G"
  }
}
```

### `k3s_ips`

Liste des adresses IP des VMs K3s :

```json
["192.168.1.102", "192.168.1.103"]
```

### `openclaw_vm`

Informations de la VM OpenClaw :

```json
{
  "name": "openclaw-01",
  "vmid": 210,
  "ip_address": "192.168.1.104",
  "memory": 4096,
  "cores": 2,
  "disk_size": "40G"
}
```

### `all_vms_summary`

Résumé global de l'infrastructure :

```json
{
  "total_vms": 3,
  "total_memory": 12288,
  "total_cores": 6,
  "storage_pool": "ssd-vms",
  "network": "vmbr0"
}
```

## 💻 Utilisation locale

### 1. Initialiser Terraform

```bash
terraform init
```

### 2. Créer un fichier de variables

Créez un fichier `terraform.tfvars` :

```hcl
# Authentification Proxmox
proxmox_api_url          = "PROXMOX_INSTANCE_URL"
proxmox_api_token_id     = "TOKEN_ID"
proxmox_api_token_secret = "votre-secret-token"

# Clés SSH (format liste - plusieurs clés possibles)
ssh_public_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOaN2/18LzwHIvnwqU+uAwMskUh0KGNyp5hE8dzQjJrR user1@hostname",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpfp++eT8Aw3tQJkHHTeTA+murV5sOMcx2GlFDwNcfF user2@hostname"
]
```

⚠️ **Ne jamais commit ce fichier** Il contient des informations sensibles.

### 3. Prévisualiser et déployer

```bash
terraform plan     # Prévisualiser les changements
terraform apply    # Déployer l'infrastructure
terraform output   # Afficher les outputs (ou -json pour le format JSON)
terraform destroy  # Détruire l'infrastructure
```

## 💾 Backend Terraform local

Le state Terraform est stocké de manière persistante sur le runner dans `/var/lib/terraform/states/homelab-infra.tfstate`.

### Configuration initiale (une seule fois)

Sur le runner GitHub Actions, exécutez ces commandes en tant que root :

```bash
# Créer les répertoires pour le state et les backups
sudo mkdir -p /var/lib/terraform/states
sudo mkdir -p /var/lib/terraform/backups

# Donner les permissions à l'utilisateur du runner (généralement 'github')
sudo chown -R github:github /var/lib/terraform
sudo chmod -R 755 /var/lib/terraform
```

### Backups automatiques

- À chaque `terraform apply`, le state est sauvegardé avec un timestamp dans `/var/lib/terraform/backups/`
- Les 10 derniers backups sont conservés automatiquement
- Un backup secondaire est uploadé comme artifact GitHub (90 jours)

### Localisation des fichiers sur le runner

```
/var/lib/terraform/
├── states/
│   └── homelab-infra.tfstate     # State principal
└── backups/
    ├── terraform.tfstate.20260217-143022
    ├── terraform.tfstate.20260217-150134
    └── ... (10 derniers backups)
```

### Restaurer un backup

```bash
# Se connecter au runner
ssh github@<runner-ip>

# Voir les backups disponibles
ls -lh /var/lib/terraform/backups/

# Restaurer un backup spécifique
cp /var/lib/terraform/backups/terraform.tfstate.20260217-143022 \
   /var/lib/terraform/states/homelab-infra.tfstate
```
