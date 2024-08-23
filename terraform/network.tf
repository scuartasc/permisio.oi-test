// Subnetwork for the GKE cluster.
resource "google_compute_subnetwork" "cluster-subnet" {
  name          = var.subnet_name
  project       = var.project
  ip_cidr_range = var.ip_range
  network       = google_compute_network.gke-network.self_link
  region        = var.region

  // A named secondary range is mandatory for a private cluster, this creates it.
  secondary_ip_range {
    range_name    = "secondary-range"
    ip_cidr_range = var.secondary_ip_range
  }
}

// https://www.terraform.io/docs/providers/google/d/datasource_compute_network.html
// A network to hold just the GKE cluster, not recommended for other instances.
resource "google_compute_network" "gke-network" {
  name                    = var.vpc_name
  project                 = var.project
  auto_create_subnetworks = false
}