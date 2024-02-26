locals {
  gcp_project_services = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "containerscanning.googleapis.com", # NOTE: Enabling this API automatically enables container vulnerability scanning. See: https://github.com/hashicorp/terraform-provider-google/issues/7644#issuecomment-1113487413
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "storage-api.googleapis.com",
  ]

  non_prod_environment_types = ["development", "staging"]

  # Disable deletion protection in non-prod environments
  deletion_protection_enabled = contains(local.non_prod_environment_types, var.env_type) ? false : true
}
