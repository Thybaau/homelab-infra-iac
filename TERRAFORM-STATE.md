# Gestion du State Terraform

## 📋 Qu'est-ce que le State Terraform ?

Le fichier `terraform.tfstate` est le **cœur de Terraform**. Il contient :

- L'état actuel de votre infrastructure (VMs, IPs, IDs Proxmox, etc.)
- Le mapping entre votre code Terraform et les ressources réelles
- Les métadonnées nécessaires pour les mises à jour et suppressions

**Sans ce fichier, Terraform ne sait pas ce qu'il a déployé** et va essayer de tout recréer, causant des conflits !

## 🏠 Backend Local : Comment ça fonctionne ?

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│              GitHub Actions Workflow                     │
│                                                          │
│  1. Checkout code                                       │
│  2. mkdir -p terraform-states terraform-backups         │
│  3. terraform init  ──────────────────┐                │
│  4. terraform plan                     │                │
│  5. terraform apply                    │                │
│                                        │                │
└────────────────────────────────────────┼────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────┐
│         Self-Hosted Runner (gh-runner-01)               │
│         192.168.1.101                                   │
│                                                          │
│  {répertoire-de-travail}/                               │
│  ├── terraform-states/                                  │
│  │   └── terraform.tfstate  ◄── State principal        │
│  └── terraform-backups/                                 │
│      ├── terraform.tfstate.20260217-143022              │
│      ├── terraform.tfstate.20260217-150134              │
│      └── ... (10 derniers backups)                      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Configuration

Le backend est configuré dans `provider.tf` avec un **chemin relatif** :

```hcl
terraform {
  backend "local" {
    path = "terraform-states/terraform.tfstate"
  }
}
```

Le chemin est relatif au répertoire de travail du workflow, ce qui rend la configuration portable et ne nécessite aucune configuration manuelle.

## 🔧 Installation Initiale

**Aucune installation manuelle nécessaire !**

Les workflows GitHub Actions créent automatiquement les répertoires nécessaires lors de la première exécution :
- `terraform-states/` - Répertoire du state
- `terraform-backups/` - Répertoire des backups

Le state est stocké dans le répertoire de travail du runner, qui est généralement :
```
/home/runner/work/{REPO_NAME}/{REPO_NAME}/terraform-states/
```

## 💾 Système de Backup

### Backups Automatiques

À chaque exécution de `terraform apply`, **deux backups** sont créés :

1. **Backup local** (sur le runner) :
   - Emplacement : `/home/runner/terraform-states/backups/`
   - Format : `terraform.tfstate.YYYYMMDD-HHMMSS`
   - Rétention : 10 derniers backups
   - Exemple : `terraform.tfstate.20260217-143022`

2. **Backup GitHub Artifact** :
   - Uploadé automatiquement après chaque apply
   - Format : `terraform-state-{run_number}`
   - Rétention : 90 jours
   - Accessible via l'onglet Actions → Run → Artifacts

### Restaurer un Backup

#### Depuis le runner (backup local)

```bash
# Se connecter au runner
ssh runner@192.168.1.101

# Aller dans le répertoire de travail du runner
# (remplacez REPO_NAME par le nom de votre repo)
cd /home/runner/work/REPO_NAME/REPO_NAME

# Voir les backups disponibles
ls -lh terraform-backups/

# Restaurer un backup spécifique
cp terraform-backups/terraform.tfstate.20260217-143022 \
   terraform-states/terraform.tfstate

# Vérifier le contenu
terraform show
```

#### Depuis GitHub Artifacts

1. Allez dans **Actions** → Sélectionnez le run → **Artifacts**
2. Téléchargez `terraform-state-{run_number}`
3. Copiez le fichier sur le runner :

```bash
# Sur votre machine locale (remplacez REPO_NAME)
scp terraform.tfstate runner@192.168.1.101:/home/runner/work/REPO_NAME/REPO_NAME/terraform-states/
```

## 🔍 Commandes Utiles

### Inspecter le State

```bash
# Sur le runner (remplacez REPO_NAME)
cd /home/runner/work/REPO_NAME/REPO_NAME

# Voir l'état complet
terraform show

# Lister les ressources
terraform state list

# Voir une ressource spécifique
terraform state show proxmox_vm_qemu.k3s_nodes[0]

# Voir les outputs
terraform output
```

### Gérer les Backups

```bash
# Lister les backups
ls -lh terraform-backups/

# Voir l'espace utilisé
du -sh terraform-states/ terraform-backups/

# Créer un backup manuel
cp terraform-states/terraform.tfstate \
   terraform-backups/terraform.tfstate.manual-$(date +%Y%m%d-%H%M%S)
```

### Nettoyer les Vieux Backups

```bash
# Garder seulement les 5 derniers backups
cd terraform-backups
ls -t terraform.tfstate.* | tail -n +6 | xargs rm
```

## 🚨 Scénarios de Récupération

### Scénario 1 : State Corrompu

**Symptôme** : Erreur lors de `terraform plan` ou `terraform apply`

**Solution** :
```bash
# Restaurer le dernier backup
cd terraform-backups
LATEST=$(ls -t terraform.tfstate.* | head -1)
cp $LATEST ../terraform-states/terraform.tfstate

# Vérifier
terraform plan
```

### Scénario 2 : Runner Détruit

**Symptôme** : Le runner a été supprimé ou réinstallé, le state est perdu

**Solution** :
1. Télécharger le dernier artifact depuis GitHub Actions
2. Réinstaller le runner
3. Copier le state téléchargé dans le répertoire de travail du runner :
   ```bash
   # Sur le runner
   cd /home/runner/work/REPO_NAME/REPO_NAME
   mkdir -p terraform-states
   # Copier le state téléchargé ici
   ```

### Scénario 3 : Désynchronisation avec Proxmox

**Symptôme** : Terraform pense que des ressources existent mais elles ont été supprimées manuellement

**Solution** :
```bash
# Supprimer la ressource du state (sans toucher à Proxmox)
terraform state rm proxmox_vm_qemu.k3s_nodes[0]

# Ou réimporter la ressource
terraform import proxmox_vm_qemu.k3s_nodes[0] pve/qemu/200
```

### Scénario 4 : Migration vers un Nouveau Runner

**Étapes** :
1. Sur l'ancien runner, copier le state :
   ```bash
   cd /home/runner/work/REPO_NAME/REPO_NAME
   scp terraform-states/terraform.tfstate \
       nouveau-runner@IP:/tmp/
   ```

2. Sur le nouveau runner :
   ```bash
   cd /home/runner/work/REPO_NAME/REPO_NAME
   mkdir -p terraform-states
   mv /tmp/terraform.tfstate terraform-states/
   ```

3. Tester :
   ```bash
   terraform plan  # Doit afficher "No changes"
   ```

## 📊 Monitoring du State

### Vérifier la Santé du State

```bash
# Taille du state
ls -lh terraform-states/terraform.tfstate

# Dernière modification
stat terraform-states/terraform.tfstate

# Nombre de ressources
terraform state list | wc -l

# Vérifier l'intégrité
terraform validate
terraform plan
```

### Alertes Recommandées

Configurez des alertes si :
- Le state n'a pas été modifié depuis > 30 jours (infrastructure figée ?)
- Le state dépasse 10 Mo (trop de ressources ?)
- Moins de 5 backups disponibles (problème de backup ?)

## 🔐 Sécurité du State

### Contenu Sensible

Le state peut contenir des informations sensibles :
- IPs des VMs
- IDs Proxmox
- Métadonnées de configuration

**Bonnes pratiques** :
- ✅ Le state est sur le runner (réseau local uniquement)
- ✅ Pas de commit du state dans Git (`.gitignore`)
- ✅ Backups chiffrés si stockés hors du runner
- ✅ Accès SSH au runner protégé par clé

### Permissions

```bash
# Vérifier les permissions
ls -la terraform-states/

# Doivent être :
# drwxr-xr-x  runner runner  (755)
# -rw-r--r--  runner runner  (644)
```

## 🔄 Migration vers un Backend Distant (Futur)

Si vous voulez migrer vers Minio ou Terraform Cloud plus tard :

1. Configurer le nouveau backend dans `provider.tf`
2. Exécuter `terraform init -migrate-state`
3. Terraform copiera automatiquement le state local vers le nouveau backend
4. Vérifier avec `terraform plan`

## 📚 Ressources

- [Terraform State Documentation](https://www.terraform.io/docs/language/state/index.html)
- [Backend Configuration](https://www.terraform.io/docs/language/settings/backends/local.html)
- [State Management Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)

---

**Dernière mise à jour** : 2026-02-17
