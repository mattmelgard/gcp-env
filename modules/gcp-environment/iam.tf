module "gcp_service_accounts" {
  source                        = "../gcp-service-accounts"
  gcp_project                   = var.gcp_project_id
  gcp_service_accounts          = var.gcp_service_accounts
  k8s_workload_service_accounts = var.k8s_workload_service_accounts
}
