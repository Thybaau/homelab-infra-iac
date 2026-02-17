#!/bin/bash

# Script pour exécuter les scans de sécurité localement
# Nécessite Docker pour exécuter les outils de scan

set -e

echo "🔒 Scan de Sécurité Local"
echo "========================="
echo ""

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour vérifier si Docker est installé
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker n'est pas installé. Installez Docker pour exécuter ce script.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker détecté${NC}"
}

# Fonction pour exécuter Gitleaks
run_gitleaks() {
    echo ""
    echo "🔍 Scan Gitleaks (détection de secrets)..."
    echo "----------------------------------------"
    
    if docker run --rm -v "$(pwd):/path" zricethezav/gitleaks:latest detect --source /path -v --no-git; then
        echo -e "${GREEN}✅ Aucun secret détecté par Gitleaks${NC}"
    else
        echo -e "${RED}❌ Secrets détectés par Gitleaks !${NC}"
        return 1
    fi
}

# Fonction pour exécuter TruffleHog
run_trufflehog() {
    echo ""
    echo "🔍 Scan TruffleHog (détection de secrets)..."
    echo "-------------------------------------------"
    
    if docker run --rm -v "$(pwd):/repo" trufflesecurity/trufflehog:latest filesystem /repo --only-verified; then
        echo -e "${GREEN}✅ Aucun secret vérifié détecté par TruffleHog${NC}"
    else
        echo -e "${RED}❌ Secrets vérifiés détectés par TruffleHog !${NC}"
        return 1
    fi
}

# Fonction pour exécuter tfsec
run_tfsec() {
    echo ""
    echo "🔍 Scan tfsec (sécurité Terraform)..."
    echo "-------------------------------------"
    
    if docker run --rm -v "$(pwd):/src" aquasec/tfsec /src --minimum-severity MEDIUM; then
        echo -e "${GREEN}✅ Aucun problème de sécurité Terraform détecté${NC}"
    else
        echo -e "${YELLOW}⚠️  Problèmes de sécurité Terraform détectés${NC}"
        return 1
    fi
}

# Fonction pour exécuter Checkov
run_checkov() {
    echo ""
    echo "🔍 Scan Checkov (conformité Terraform)..."
    echo "----------------------------------------"
    
    if docker run --rm -v "$(pwd):/tf" bridgecrew/checkov -d /tf --framework terraform --quiet; then
        echo -e "${GREEN}✅ Aucun problème de conformité détecté${NC}"
    else
        echo -e "${YELLOW}⚠️  Problèmes de conformité détectés${NC}"
        return 1
    fi
}

# Fonction pour exécuter Trivy
run_trivy() {
    echo ""
    echo "🔍 Scan Trivy (vulnérabilités)..."
    echo "--------------------------------"
    
    if docker run --rm -v "$(pwd):/scan" aquasec/trivy config /scan --severity CRITICAL,HIGH,MEDIUM; then
        echo -e "${GREEN}✅ Aucune vulnérabilité critique détectée${NC}"
    else
        echo -e "${YELLOW}⚠️  Vulnérabilités détectées${NC}"
        return 1
    fi
}

# Fonction pour vérifier les fichiers sensibles
check_sensitive_files() {
    echo ""
    echo "🔍 Vérification des fichiers sensibles..."
    echo "----------------------------------------"
    
    SENSITIVE_FILES=$(git ls-files 2>/dev/null | grep -E '\.tfvars$|\.tfstate$|id_rsa$|\.pem$|\.key$' || true)
    
    if [ -z "$SENSITIVE_FILES" ]; then
        echo -e "${GREEN}✅ Aucun fichier sensible commité${NC}"
    else
        echo -e "${RED}❌ Fichiers sensibles détectés dans Git :${NC}"
        echo "$SENSITIVE_FILES"
        return 1
    fi
}

# Fonction pour vérifier le format Terraform
check_terraform_fmt() {
    echo ""
    echo "🔍 Vérification du format Terraform..."
    echo "-------------------------------------"
    
    if terraform fmt -check -recursive; then
        echo -e "${GREEN}✅ Format Terraform correct${NC}"
    else
        echo -e "${YELLOW}⚠️  Format Terraform incorrect. Exécutez 'terraform fmt -recursive'${NC}"
        return 1
    fi
}

# Fonction pour valider Terraform
validate_terraform() {
    echo ""
    echo "🔍 Validation Terraform..."
    echo "-------------------------"
    
    terraform init -backend=false > /dev/null 2>&1
    
    if terraform validate; then
        echo -e "${GREEN}✅ Configuration Terraform valide${NC}"
    else
        echo -e "${RED}❌ Configuration Terraform invalide${NC}"
        return 1
    fi
}

# Menu principal
main() {
    check_docker
    
    echo ""
    echo "Sélectionnez les scans à exécuter :"
    echo "1) Tous les scans"
    echo "2) Scan de secrets uniquement (Gitleaks + TruffleHog)"
    echo "3) Scan Terraform uniquement (tfsec + Checkov + Trivy)"
    echo "4) Scan rapide (Gitleaks + tfsec)"
    echo "5) Quitter"
    echo ""
    read -p "Votre choix [1-5]: " choice
    
    FAILED=0
    
    case $choice in
        1)
            echo -e "${YELLOW}Exécution de tous les scans...${NC}"
            check_sensitive_files || FAILED=1
            check_terraform_fmt || FAILED=1
            validate_terraform || FAILED=1
            run_gitleaks || FAILED=1
            run_trufflehog || FAILED=1
            run_tfsec || FAILED=1
            run_checkov || FAILED=1
            run_trivy || FAILED=1
            ;;
        2)
            echo -e "${YELLOW}Exécution des scans de secrets...${NC}"
            check_sensitive_files || FAILED=1
            run_gitleaks || FAILED=1
            run_trufflehog || FAILED=1
            ;;
        3)
            echo -e "${YELLOW}Exécution des scans Terraform...${NC}"
            check_terraform_fmt || FAILED=1
            validate_terraform || FAILED=1
            run_tfsec || FAILED=1
            run_checkov || FAILED=1
            run_trivy || FAILED=1
            ;;
        4)
            echo -e "${YELLOW}Exécution du scan rapide...${NC}"
            check_sensitive_files || FAILED=1
            run_gitleaks || FAILED=1
            run_tfsec || FAILED=1
            ;;
        5)
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo "========================="
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ Tous les scans ont réussi !${NC}"
        exit 0
    else
        echo -e "${RED}❌ Certains scans ont échoué. Consultez les détails ci-dessus.${NC}"
        exit 1
    fi
}

# Exécuter le script
main
