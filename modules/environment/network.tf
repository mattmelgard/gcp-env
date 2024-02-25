locals {
  network_namespace_prefix         = "${var.env_name}-${var.gcp_region}"
  main_cluster_subnet_name         = "${local.network_namespace_prefix}-main-cluster-subnet"
  main_cluster_pod_subnet_name     = "${local.network_namespace_prefix}-main-cluster-pods-subnet"
  main_cluster_service_subnet_name = "${local.network_namespace_prefix}-main-cluster-services-subnet"
  main_vpc_router_name             = "${local.network_namespace_prefix}-router"
  main_vpc_nat_name                = "${local.network_namespace_prefix}-nat"
  nat_router_compute_address_count = 2
}

resource "google_compute_network" "main" {
  project                 = var.gcp_project_id
  name                    = "main"
  description             = "The main network for this environment's GCP project"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "main_cluster" {
  project                    = var.gcp_project_id
  name                       = local.main_cluster_pod_subnet_name
  description                = "The VPC subnet for the main cluster in this environment"
  region                     = var.gcp_region
  network                    = google_compute_network.main.self_link
  private_ip_google_access   = true
  private_ipv6_google_access = true
  ip_cidr_range              = var.main_cluster_subnet_cidr
  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  secondary_ip_range {
    range_name    = local.main_cluster_pod_subnet_name
    ip_cidr_range = var.main_cluster_pod_cidr
  }
  secondary_ip_range {
    range_name    = local.main_cluster_service_subnet_name
    ip_cidr_range = var.main_cluster_services_cidr
  }
}

resource "google_compute_router" "main" {
  name    = local.main_vpc_nat_name
  description = "The main NAT enabled Cloud Router for this environment"
  project = var.gcp_project_id
  region  = var.gcp_region
  network = google_compute_network.main.self_link
}

resource "google_compute_address" "nat_gateway_manual_ip" {
  count   = var.enable_manual_nat_ip ? local.nat_router_compute_address_count : 0
  name    = "nat-manual-ip-${count.index}"
  project = var.gcp_project_id
  region  = google_compute_subnetwork.main_cluster.region
}

resource "google_compute_router_nat" "main" {
  name                               = local.main_vpc_nat_name
  project                            = var.gcp_project_id
  region                             = var.gcp_region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = var.enable_manual_nat_ip ? "MANUAL_ONLY" : "AUTO_ONLY"
  nat_ips                            = var.enable_manual_nat_ip ? google_compute_address.nat_gateway_manual_ip.*.self_link : null
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.main_cluster.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  lifecycle {
    ignore_changes = [
      min_ports_per_vm
    ]
  }
}
