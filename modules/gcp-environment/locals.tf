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

  network_namespace_prefix                        = "${var.env_name}-${var.gcp_region}"
  main_cluster_subnet_name                        = "${local.network_namespace_prefix}-main-cluster-subnet"
  main_cluster_pod_subnet_name                    = "${local.network_namespace_prefix}-main-cluster-pods-subnet"
  main_cluster_service_subnet_name                = "${local.network_namespace_prefix}-main-cluster-services-subnet"
  main_vpc_router_name                            = "${local.network_namespace_prefix}-router"
  main_vpc_nat_name                               = "${local.network_namespace_prefix}-nat"
  nat_router_compute_address_count                = 2
  internal_ingress_tag                            = "internal-ingress"
  main_cluster_name                               = "main"
  main_cluster_service_account_name               = "${local.main_cluster_name}-sa"
  main_cluster_default_master_authorized_networks = []
  # https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa
  main_cluster_sa_default_roles = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ])
  required_node_tags = [local.internal_ingress_tag]
}
