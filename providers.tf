terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # boundary = {
    #   source  = "hashicorp/boundary"
    #   version = "~> 1.1"
    # }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3"
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# provider "boundary" {
#   addr                   = var.hcp_boundary_cluster_url
#   auth_method_id         = var.boundary_auth_method_id
#   auth_method_login_name = "tommy"
#   auth_method_password   = var.boundary_admin_password
# }

provider "vault" {}