# Gets the current version of Kubernetes engine
data "google_container_engine_versions" "gke_version" {
  location   = var.zone
}

// https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
// Create the primary cluster for this project.
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  project            = var.project
  location           = var.zone
  network            = google_compute_network.gke-network.self_link
  subnetwork         = google_compute_subnetwork.cluster-subnet.self_link
  initial_node_count = var.initial_node_count
  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version
  node_locations   = []

  // Scopes necessary for the nodes to function correctly
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    machine_type = var.node_machine_type
    image_type   = "COS_CONTAINERD"

    // (Optional) The Kubernetes labels (key/value pairs) to be applied to each node.
    labels = {
      status = "poc"
    }

    // (Optional) The list of instance tags applied to all nodes.
    // Tags are used to identify valid sources or targets for network firewalls.
    tags = ["poc"]
  }

  // (Required for private cluster, optional otherwise) Configuration for cluster IP allocation.
  // As of now, only pre-allocated subnetworks (custom type with
  // secondary ranges) are supported. This will activate IP aliases.
  ip_allocation_policy {
    cluster_secondary_range_name = "secondary-range"
  }

  // In a private cluster, the master has two IP addresses, one public and one
  // private. Nodes communicate to the master through this private IP address.
  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = "10.0.90.0/28"
    enable_private_endpoint = false      
  }

  // (Required for private cluster, optional otherwise) network (cidr) from which cluster is accessible
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = join("/", [google_compute_instance.gke-bastion.network_interface[0].access_config[0].nat_ip, "32"])

    }
  }

  // Required for Calico, optional otherwise.
  // Configuration options for the NetworkPolicy feature
  network_policy {
    enabled  = true
    provider = "CALICO" // CALICO is currently the only supported provider
  }

  // Required for network_policy enabled cluster, optional otherwise
  // Addons config supports other options as well, see:
  // https://www.terraform.io/docs/providers/google/r/container_cluster.html#addons_config
  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  // This is required to workaround a perma-diff bug in terraform:
  // see: https://github.com/terraform-providers/terraform-provider-google/issues/1382
  lifecycle {
    ignore_changes = [
      ip_allocation_policy,
      network,
      subnetwork,
    ]
  }
  // Etherium module from Docker
  module "container-server" {
    source = "../.."

    domain = "app.${var.domain}"
    email  = var.email

    letsencrypt_staging = true # delete this or set to false to enable production Let's Encrypt certificates
    enable_webhook      = true

    files = [
      {
        filename = "docker-compose.yaml"
        content  = filebase64("${path.module}/yamls/docker-compose.yaml")
      },
      # https://docs.traefik.io/v2.0/middlewares/basicauth/#usersfile
      {
        filename = "users"
        content  = filebase64("${path.module}/assets/users")
      }
    ]

    env = {
      IMAGE                 = "containous/whoami:latest"
      TRAEFIK_API_DASHBOARD = true
    }

    # custom instance configuration is possible through supplemental cloud-init config(s)
    cloudinit_part = [
      {
        content_type = "text/cloud-config"
        content      = local.cloudinit_configure_gcr
      }
    ]

  }

}

