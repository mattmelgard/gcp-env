terraform {
  required_version = "1.7.3"
  required_providers {
    google = {
      version = "= 5.17.0"
      source  = "hashicorp/google"
    }
  }
}

module "environment" {
  source         = "../modules/environment"
  env_name       = "my-env"
  env_type       = "production"
  gcp_project_id = var.gcp_project_id
}
