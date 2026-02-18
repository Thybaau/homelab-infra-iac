# Validation des Workflows GitHub Actions

## Date de validation
2026-02-17

## Résultats de la validation

### ✅ 1. Syntaxe YAML
Tous les fichiers workflow sont syntaxiquement valides:
- `.github/workflows/terraform-plan.yml`
- `.github/workflows/terraform-apply.yml`
- `.github/workflows/terraform-drift.yml`
- `.github/workflows/terraform-destroy.yml`

### ✅ 2. Configuration Self-Hosted Runner
Tous les workflows utilisent correctement `runs-on: self-hosted`:
- **terraform-plan.yml**: ✅ self-hosted
- **terraform-apply.yml**: ✅ self-hosted
- **terraform-drift.yml**: ✅ self-hosted (avec commentaire explicatif)
- **terraform-destroy.yml**: ✅ self-hosted (avec commentaire explicatif)

**Justification**: Proxmox VE n'est pas accessible depuis Internet, donc l'utilisation d'un runner self-hosted sur le réseau local (gh-runner-01 @ 192.168.1.101) est obligatoire.

### ✅ 3. Secrets GitHub Requis
Les secrets suivants sont utilisés dans les workflows:

| Secret | Description | Utilisé dans |
|--------|-------------|--------------|
| `PM_API_URL` | URL de l'API Proxmox (https://192.168.1.200:8006/api2/json) | 4 workflows |
| `PM_API_TOKEN_ID` | Token ID Proxmox (ex: terraform@pam!terraform) | 4 workflows |
| `PM_API_TOKEN_SECRET` | Secret du token Proxmox | 4 workflows |

**Configuration requise**:
1. Aller dans Settings > Secrets and variables > Actions de votre dépôt GitHub
2. Ajouter les 3 secrets ci-dessus avec les valeurs appropriées

### ⚠️ 4. Self-Hosted Runner gh-runner-01

**Spécifications requises**:
- Nom: `gh-runner-01`
- Type: Conteneur LXC
- RAM: 2 Go
- IP: 192.168.1.101
- Statut: Actif et connecté à GitHub Actions

**Vérification manuelle requise**:
1. Accéder à Settings > Actions > Runners dans votre dépôt GitHub
2. Vérifier que `gh-runner-01` apparaît dans la liste
3. Confirmer que le statut est "Idle" (inactif) ou "Active" (en cours d'exécution)
4. Si le runner n'apparaît pas, suivre la documentation GitHub pour l'installation:
   - https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners

**Note importante**: Sans ce runner actif, aucun workflow ne pourra s'exécuter car Proxmox n'est accessible que sur le réseau local.

## Script de validation

Un script `validate-workflows.sh` a été créé pour automatiser cette validation. Pour l'exécuter:

```bash
./validate-workflows.sh
```

## Prochaines étapes

1. ✅ Validation des workflows terminée
2. ⚠️ Configurer les secrets GitHub (PM_API_URL, PM_API_TOKEN_ID, PM_API_TOKEN_SECRET)
3. ⚠️ Vérifier que gh-runner-01 est actif dans GitHub Actions
4. 📝 Continuer avec la tâche 13: Créer la documentation README
