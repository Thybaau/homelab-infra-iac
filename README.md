# Infrastructure Terraform pour Proxmox VE

[![Security Scan](https://github.com/Thybaau/homelab-infra-iac/actions/workflows/security-scan.yml/badge.svg)](https://github.com/VOTRE-USERNAME/VOTRE-REPO/actions/workflows/security-scan.yml)
[![Terraform Plan](https://github.com/Thybaau/homelab-infra-iac/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/VOTRE-USERNAME/VOTRE-REPO/actions/workflows/terraform-plan.yml)

Projet Terraform pour le provisionnement automatisé de machines virtuelles sur Proxmox VE 9.1.5, déployé via des pipelines GitHub Actions.

## ✨ Fonctionnalités

- 📋 **Plan automatique** sur chaque Pull Request modifiant des fichiers `.tf`, avec commentaire du plan directement sur la PR
- 🚀 **Déploiement** des VMs via workflow manuel (`terraform apply`)
- 🔍 **Détection de drift** automatique tous les lundis à 8h — crée une issue GitHub avec le détail du plan si une dérive est détectée
- 🗑️ **Destruction contrôlée** via workflow manuel avec confirmation obligatoire (`DESTROY`)
- 🔒 **Scan de sécurité** automatique (secrets, Terraform, dépendances) sur chaque push/PR + scan hebdomadaire le lundi à 2h
- 💾 **Backup automatique** du state Terraform après chaque apply, avec rétention des 10 derniers backups

## 📊 Architecture Déploiement

Déploiement avec valeurs par défaut :

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Terraform    │  │ Terraform    │  │   Drift      │       │
│  │    Plan      │  │    Apply     │  │  Detection   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Self-hosted runner
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox VE 9.1.5                         │
│                                                             │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  k3s-node-01    │  │  k3s-node-02    │  │ openclaw-01 │  │
│  │  192.168.1.102  │  │  192.168.1.103  │  │192.168.1.104│  │
│  │  4 Go RAM       │  │  4 Go RAM       │  │  4 Go RAM   │  │
│  │  2 vCPUs        │  │  2 vCPUs        │  │  2 vCPUs    │  │
│  │  32 Go SSD      │  │  32 Go SSD      │  │  40 Go SSD  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
│                                                             │
│  Storage: ssd-vms (125 Go)                                  │
│  Network: vmbr0 (192.168.1.0/24)                            │
└─────────────────────────────────────────────────────────────┘
```


## 🚀 Utilisation des Workflows GitHub Actions

### 1. Terraform Plan

**Objectif** : Prévisualiser les changements d'infrastructure sans les appliquer.

**Déclenchement** :
- Automatique sur les Pull Requests modifiant des fichiers `.tf`
- Manuel via l'onglet **Actions** → **Terraform Plan** → **Run workflow**

**Paramètres** : Aucun

**Résultat** : Le plan est affiché dans les logs et commenté automatiquement sur la PR.

### 2. Terraform Apply

**Objectif** : Déployer l'infrastructure Proxmox automatiquement.

**Déclenchement** : Manuel uniquement via l'onglet **Actions** → **Terraform Apply** → **Run workflow**

**Paramètres** : Aucun (les clés SSH sont automatiquement récupérées depuis le secret `SSH_PUBLIC_KEYS`)

**Résultat** : Les VMs sont créées dans Proxmox et les IPs sont affichées dans les logs.

### 3. Terraform Drift Detection

**Objectif** : Détecter les modifications manuelles non documentées dans Proxmox.

**Déclenchement** :
- Automatique tous les lundis à 8h (cron)
- Manuel via l'onglet **Actions** → **Terraform Drift Detection** → **Run workflow**

**Paramètres** : Aucun

**Résultat** : 
- Si une dérive est détectée, une issue GitHub est créée automatiquement
- Les différences sont affichées dans les logs

### 4. Terraform Destroy

**Objectif** : Détruire l'infrastructure de manière contrôlée.

**Déclenchement** : Manuel uniquement via l'onglet **Actions** → **Terraform Destroy** → **Run workflow**

**Paramètres requis** :
- `confirm_destroy` : Tapez exactement `DESTROY` pour confirmer

**Résultat** : Toutes les VMs sont supprimées de Proxmox.

⚠️ **ATTENTION** : Cette action est irréversible.

### 5. Security Scan

**Objectif** : Détecter les secrets en dur, vulnérabilités de sécurité et problèmes de configuration.

**Déclenchement** :
- Automatique sur push vers `main` ou `develop`
- Automatique sur les Pull Requests
- Automatique tous les lundis à 2h (cron)
- Manuel via l'onglet **Actions** → **Security Scan** → **Run workflow**

**Paramètres** : Aucun

**Scans effectués** :
- **TruffleHog** : Détection de secrets dans l'historique Git
- **Gitleaks** : Détection de secrets et credentials
- **tfsec** : Analyse de sécurité Terraform (misconfigurations, best practices)
- **Checkov** : Scan de conformité et sécurité Terraform
- **Trivy** : Scan de vulnérabilités dans les configurations
- **Workflow Security** : Validation des workflows GitHub Actions

**Résultat** : 
- Les vulnérabilités sont affichées dans l'onglet **Security** de GitHub
- Un rapport de sécurité est généré et disponible en artifact
- Sur les PRs, un commentaire automatique résume les résultats

## 🔧 Variables Terraform

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

## 📤 Outputs Terraform

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

## 💻 Exemples d'Utilisation

### Déploiement local avec Terraform

#### 1. Initialiser Terraform

```bash
terraform init
```

#### 2. Créer un fichier de variables

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

#### 3. Prévisualiser les changements

### Configuration du Backend Terraform Local

Le state Terraform est stocké de manière persistante sur le runner dans `/var/lib/terraform/states/homelab-infra.tfstate`.

**Configuration initiale requise (une seule fois):**

Sur le runner GitHub Actions, exécutez ces commandes en tant que root:

```bash
# Créer les répertoires pour le state et les backups
sudo mkdir -p /var/lib/terraform/states
sudo mkdir -p /var/lib/terraform/backups

# Donner les permissions à l'utilisateur du runner (généralement 'github')
sudo chown -R github:github /var/lib/terraform
sudo chmod -R 755 /var/lib/terraform
```

**Backups automatiques** :
- À chaque `terraform apply`, le state est sauvegardé avec un timestamp dans `/var/lib/terraform/backups/`
- Les 10 derniers backups sont conservés automatiquement
- Un backup secondaire est uploadé comme artifact GitHub (90 jours)

**Localisation des fichiers sur le runner** :
```
/var/lib/terraform/
├── states/
│   └── homelab-infra.tfstate     # State principal
└── backups/
    ├── terraform.tfstate.20260217-143022
    ├── terraform.tfstate.20260217-150134
    └── ... (10 derniers backups)
```

**Restaurer un backup** :
```bash
# Se connecter au runner
ssh github@<runner-ip>

# Voir les backups disponibles
ls -lh /var/lib/terraform/backups/

# Restaurer un backup spécifique
cp /var/lib/terraform/backups/terraform.tfstate.20260217-143022 \
   /var/lib/terraform/states/homelab-infra.tfstate
```

## 🔒 Sécurité

### Bonnes Pratiques Implémentées

- Les credentials Proxmox sont stockés dans GitHub Secrets (chiffrés)
- Les variables sensibles sont marquées `sensitive = true` dans Terraform
- L'authentification SSH par mot de passe est désactivée sur les VMs
- Seule l'authentification par clé SSH est autorisée
- Le certificat TLS auto-signé de Proxmox est accepté (`pm_tls_insecure = true`)

### Scan de Sécurité Automatique

Le workflow **Security Scan** s'exécute automatiquement pour détecter :

1. **Secrets en dur** : Détection de tokens, mots de passe, clés API dans le code
2. **Vulnérabilités Terraform** : Misconfigurations, non-respect des best practices
3. **Problèmes de dépendances** : Vulnérabilités dans les providers Terraform
4. **Sécurité des workflows** : Validation des GitHub Actions workflows

### Fichiers de Configuration Sécurité

- `.gitleaks.toml` : Configuration pour la détection de secrets
- `.tfsec.yml` : Configuration pour le scan de sécurité Terraform
- `.gitignore` : Exclusion des fichiers sensibles (`.tfvars`, `.tfstate`)

### Consulter les Résultats de Sécurité

1. Aller dans l'onglet **Security**
2. Consulter **Code scanning alerts** pour les vulnérabilités détectées
3. Téléchargez le rapport de sécurité depuis les artifacts du workflow

### Scan de Sécurité Local

Possibilité d'exécuter les scans de sécurité localement :

```bash
# Rendre le script exécutable (première fois uniquement)
chmod +x security-scan-local.sh

# Exécuter le script
./security-scan-local.sh
```

Le script propose plusieurs options :
1. **Tous les scans** : Exécute tous les outils de sécurité
2. **Scan de secrets uniquement** : Gitleaks + TruffleHog
3. **Scan Terraform uniquement** : tfsec + Checkov + Trivy
4. **Scan rapide** : Gitleaks + tfsec (recommandé avant chaque commit)

**Prérequis** : Docker doit être installé sur votre machine.

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 📚 Ressources

- [Documentation Terraform](https://www.terraform.io/docs)
- [Provider Terraform Proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Documentation Proxmox VE](https://pve.proxmox.com/pve-docs/)
- [Documentation Cloud-Init](https://cloudinit.readthedocs.io/)
- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Gestion du State Terraform](TERRAFORM-STATE.md) - Guide complet sur le backend local
- [🚀 Guide Rapide SSH](QUICK-START-SSH.md) - Configuration rapide des clés SSH en 3 étapes
- [Configuration des Variables GitHub](GITHUB-SECRETS-SETUP.md) - Guide détaillé pour configurer les clés SSH
- [Changelog SSH Keys](CHANGELOG-SSH-KEYS.md) - Détails de la migration vers multi-clés
