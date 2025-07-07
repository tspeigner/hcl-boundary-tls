variable "project_name" {
  description = "A unique name for the project, used for tagging and naming resources."
  type        = string
  default     = "boundary-vault-pg"
}

variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "public_key" {
  description = "The public SSH key to be installed on EC2 instances for access."
  type        = string
  default     = null # Must be provided via environment variable (e.g., TF_VAR_public_key) or a .tfvars file
}

# variable "hcp_boundary_cluster_url" {
#   description = "The URL of the HCP Boundary cluster."
#   type        = string
#   default     = null
# }

# variable "hcp_boundary_project_id" {
#   description = "The ID of the HCP Boundary project (e.g., p_...)."
#   type        = string
#   default     = null
# }

# variable "boundary_auth_method_id" {
#   description = "The ID of the password auth method for Boundary (e.g., ampw_...)."
#   type        = string
#   default     = null
# }

# variable "boundary_admin_password" {
#   description = "The password for the Boundary user specified in the provider configuration."
#   type        = string
#   sensitive   = true
#   default     = null
# }

variable "vault_version" {
  description = "The version of Vault to install."
  type        = string
  default     = "1.15.2"
}

# variable "boundary_version" {
#   description = "The version of the Boundary worker to install."
#   type        = string
#   default     = "0.14.1"
# }

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "tommy"
}