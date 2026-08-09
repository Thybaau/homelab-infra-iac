# Politique de Sécurité

## 🛡️ Mesures de Sécurité Implémentées

### 1. Gestion des Secrets

#### ✅ Ce qui est sécurisé

- **GitHub Secrets** : Tous les credentials Proxmox sont stockés dans GitHub Secrets
- **Variables Terraform sensibles** : Marquées avec `sensitive = true`
- **Exclusion Git** : Les fichiers `.tfvars` et `.tfstate` sont dans `.gitignore`
- **Scan automatique** : Détection de secrets en dur via TruffleHog et Gitleaks

#### ❌ Ce qui ne doit JAMAIS être commité

- Fichiers `terraform.tfvars` avec des valeurs réelles
- Fichiers `terraform.tfstate` ou `terraform.tfstate.backup`
- Tokens API Proxmox
- Clés SSH privées
- Mots de passe en clair
- URLs avec credentials intégrées

### 2. Authentification et Accès

#### Proxmox API

- **Token API** : Utilisation de tokens API au lieu de mots de passe
- **Permissions minimales** : Le token doit avoir uniquement les permissions nécessaires (éviter `root@pam`)
- **Rotation régulière** : Changez les tokens API tous les 90 jours
- **TLS** : Connexion HTTPS obligatoire

> ⚠️ **Risque accepté** : `pm_tls_insecure = true` est activé car Proxmox utilise un certificat auto-signé en homelab. Cela expose à des attaques MITM sur le réseau local. Pour mitiger : importer le CA Proxmox dans le trust store du runner (`/usr/local/share/ca-certificates/`) et passer à `pm_tls_insecure = false`.

#### VMs

- **SSH par clé uniquement** : Authentification par mot de passe désactivée
- **Utilisateurs dédiés** : Utilisateur `k3s` pour les VMs K3s, `admin` pour OpenClaw (créés via Cloud-Init)
- **Pas de root direct** : Connexion root SSH désactivée
- **Clés SSH uniques** : Une clé SSH par utilisateur/environnement

### 3. Infrastructure as Code

#### Terraform

- **Provider version pinning** : Version du provider fixée (`3.0.2-rc07` — pré-release, à migrer vers une version stable dès disponible)
- **Validation des contraintes** : Vérification des limites RAM/stockage/mot de passe avant déploiement
- **State sécurisé** : Le state est stocké localement sur le runner self-hosted (`/var/lib/terraform/states/`)
- **Attention** : Le state Terraform contient des secrets en clair (mots de passe VM, tokens). Ne jamais l'exposer comme artifact ou le commiter.

> ⚠️ **Provider en RC** : `Telmate/proxmox 3.0.2-rc07` est une pré-release. Les RC ne bénéficient pas du même niveau d'audit de sécurité qu'une release stable. Migrer vers une version stable dès qu'elle est disponible.

#### GitHub Actions

- **Self-hosted runner** : Isolation réseau (Proxmox non accessible depuis Internet)
- **Permissions minimales** : Chaque workflow a des permissions explicites (`contents: read` par défaut)
- **Versions pinnées par SHA** : Actions GitHub épinglées par commit SHA pour prévenir les attaques supply-chain
- **Secrets masqués** : Les secrets sont automatiquement masqués dans les logs

### 4. Scan de Sécurité Automatique

Le workflow **Security Scan** s'exécute automatiquement et inclut :

#### TruffleHog
- Détecte les secrets dans l'historique Git complet
- Vérifie les secrets vérifiés (haute confiance)
- Scan de tous les commits, pas seulement le dernier

#### Gitleaks
- Détection de patterns de secrets (API keys, tokens, passwords)
- Règles personnalisées pour Proxmox
- Configuration via `.gitleaks.toml`

#### tfsec
- Analyse statique de sécurité Terraform
- Détection de misconfigurations
- Vérification des best practices
- Configuration via `.tfsec.yml`

#### Checkov
- Scan de conformité et sécurité
- Vérification des politiques de sécurité
- Détection de ressources non sécurisées

#### Trivy
- Scan de vulnérabilités dans les configurations
- Détection de CVEs
- Analyse des dépendances

#### Workflow Security
- Validation des workflows GitHub Actions
- Vérification des versions pinnées
- Détection de l'utilisation de secrets

### 5. Réseau et Isolation

- **Réseau privé** : Proxmox sur réseau local uniquement (192.168.1.0/24)
- **Pas d'exposition Internet** : Aucun service exposé publiquement
- **IPs statiques** : Hors plage DHCP pour éviter les conflits

## 🔍 Audit de Sécurité

### Vérifications Manuelles Recommandées

#### Tous les mois

- [ ] Vérifier les logs d'accès Proxmox
- [ ] Vérifier les connexions SSH aux VMs
- [ ] Consulter les alertes de sécurité GitHub
- [ ] Vérifier l'état du self-hosted runner

#### Tous les trimestres

- [ ] Rotation des tokens API Proxmox
- [ ] Mise à jour de Terraform et des providers
- [ ] Mise à jour de Proxmox VE
- [ ] Audit des permissions GitHub

#### Tous les ans

- [ ] Rotation des clés SSH
- [ ] Revue complète de la configuration de sécurité
- [ ] Test de restauration depuis backup
- [ ] Audit de sécurité externe (optionnel)

### Commandes d'Audit

#### Vérifier les secrets dans le code

```bash
# Scan local avec Gitleaks
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path -v

# Scan local avec TruffleHog
docker run --rm -v $(pwd):/repo trufflesecurity/trufflehog:latest filesystem /repo
```

#### Vérifier la sécurité Terraform

```bash
# Scan avec tfsec
docker run --rm -v $(pwd):/src aquasec/tfsec /src

# Scan avec Checkov
docker run --rm -v $(pwd):/tf bridgecrew/checkov -d /tf
```

#### Vérifier les permissions des fichiers

```bash
# Vérifier qu'aucun fichier sensible n'est commité
git ls-files | grep -E '\.tfvars$|\.tfstate$|id_rsa$'

# Vérifier les permissions locales
find . -name "*.tfvars" -o -name "*.tfstate" -o -name "id_rsa"
```

## 📋 Checklist de Sécurité pour les Contributeurs

Avant de créer une Pull Request, vérifiez :

- [ ] Aucun secret en dur dans le code
- [ ] Aucun fichier `.tfvars` avec des valeurs réelles
- [ ] Aucun fichier `.tfstate` commité
- [ ] Les variables sensibles sont marquées `sensitive = true`
- [ ] Les exemples utilisent des valeurs fictives
- [ ] Le workflow Security Scan passe sans erreur
- [ ] Les credentials sont documentés dans le README (mais pas les valeurs)
- [ ] Les nouvelles variables sensibles sont ajoutées aux GitHub Secrets

## 🚨 Réponse aux Incidents

### En cas de fuite de secret

1. **Révoquer immédiatement** le secret compromis
2. **Générer un nouveau secret** dans Proxmox
3. **Mettre à jour** le GitHub Secret
4. **Vérifier les logs** Proxmox pour détecter une utilisation non autorisée
5. **Notifier** les mainteneurs du projet
6. **Documenter** l'incident pour éviter qu'il se reproduise

### En cas de vulnérabilité détectée

1. **Évaluer la criticité** (CVSS score)
2. **Vérifier l'exploitabilité** dans votre contexte
3. **Appliquer le patch** ou la mise à jour
4. **Tester** que l'infrastructure fonctionne toujours
5. **Documenter** la correction

## 📚 Ressources de Sécurité

### Documentation

- [OWASP Infrastructure as Code Security](https://owasp.org/www-project-devsecops-guideline/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Proxmox VE Security](https://pve.proxmox.com/wiki/Security)

### Outils

- [TruffleHog](https://github.com/trufflesecurity/trufflehog) - Détection de secrets
- [Gitleaks](https://github.com/gitleaks/gitleaks) - Détection de secrets
- [tfsec](https://github.com/aquasecurity/tfsec) - Scan de sécurité Terraform
- [Checkov](https://github.com/bridgecrewio/checkov) - Scan de conformité
- [Trivy](https://github.com/aquasecurity/trivy) - Scan de vulnérabilités

## 📞 Contact

Pour toute question de sécurité, contactez les mainteneurs du projet via les canaux privés.

---

**Dernière mise à jour** : 2026-08-09
