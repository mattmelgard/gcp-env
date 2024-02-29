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
  name        = local.main_vpc_nat_name
  description = "The main NAT enabled Cloud Router for this environment"
  project     = var.gcp_project_id
  region      = var.gcp_region
  network     = google_compute_network.main.self_link
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

# This firewall rule is required because the main cluster uses a private cluster topology
# that restricts Google's GKE control plane access. to only allow TCP connections to nodes/pods
# on ports 443 (HTTPS) and 10250 (kubelet) by default. Thus in order to run services that require
# communication with the control plane on other ports, we need to explicitly allow it.
# Ref: https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#add_firewall_rules
resource "google_compute_firewall" "gke_control_plane_tcp_port_node_access" {
  count = length(var.main_cluster_authorized_control_plane_ports) > 0 ? 1 : 0
  project       = var.gcp_project_id
  name          = "main-cluster-control-plane-tcp-node-access"
  description   = <<-EOT
    Allows the GKE control plane nodes to reach worker nodes on certain ports to make it possible to run certain cluster services
    that need to communicate with the control plane with a private cluster topology
  EOT
  network       = google_compute_network.main.self_link
  source_ranges = [var.main_cluster_master_cidr]
  allow {
    protocol = "tcp"
    ports    = var.main_cluster_authorized_control_plane_ports
  }
  target_tags = [local.internal_ingress_tag]
}
