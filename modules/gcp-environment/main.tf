terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.64, < 6"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.64, < 6"
    }
  }
}

resource "google_project_service" "project_services" {
  for_each                   = toset(concat(local.gcp_project_services, var.gcp_services))
  project                    = var.gcp_project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
