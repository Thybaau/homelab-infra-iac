terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }

  # Backend local pour stocker le state sur le self-hosted runner
  # Chemin relatif au répertoire de travail du workflow
  backend "local" {
    path = "terraform-states/terraform.tfstate"
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_timeout          = 600
  pm_parallel         = 2
}
