terraform {
  required_version = "1.7.3"
  required_providers {
    google = {
      version = "= 5.17.0"
      source  = "hashicorp/google"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
  }
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

module "environment" {
  source         = "../modules/gcp-environment"
  env_name       = "my-env"
  env_type       = "development"
  gcp_project_id = var.gcp_project_id
  # NOTE: This allows the local user creating the cluster with Terraform to access it for demonstrative purposes
  # This configuration would **not** be used in a real environment
  main_cluster_master_authorized_networks = [{
    display_name = "local-user"
    cidr_block   = "${chomp(data.http.myip.response_body)}/32"
  }]
  main_cluster_node_pools = {
    default = {
      min_node_count = 1
      max_node_count = 3
      machine_type   = "n1-standard-2"
    },
  }
}
