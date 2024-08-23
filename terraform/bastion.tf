data "template_file" "startup_script" {
  template = <<EOF
sudo apt-get update -y
sudo apt-get install -y kubectl
echo "gcloud container clusters get-credentials $${cluster_name} --zone $${cluster_zone} --project $${project}" >> /etc/profile
EOF


  vars = {
    cluster_name = var.cluster_name
    cluster_zone = var.zone
    project = var.project
  }
}

// https://www.terraform.io/docs/providers/google/r/compute_instance.html
// bastion host for access and administration of a private cluster.

resource "google_compute_instance" "gke-bastion" {
  name = var.bastion_hostname
  machine_type = var.bastion_machine_type
  zone = var.zone
  project = var.project
  tags = var.bastion_tags
  allow_stopping_for_update = true

  // Specify the Operating System Family and version.
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Define a network interface in the correct subnet.
  network_interface {
    subnetwork = google_compute_subnetwork.cluster-subnet.self_link

    // Add an ephemeral external IP.
    access_config {
      // Implicit ephemeral IP
    }
  }

  // Ensure that when the bastion host is booted, it will have kubectl.
  # metadata_startup_script = "sudo apt-get install -y kubectl"
  metadata_startup_script = data.template_file.startup_script.rendered

  // Necessary scopes for administering kubernetes.
  service_account {
    scopes = ["testmail@mail.com", "permission-ro", "perminnion-io-ro", "gcp"]
  }

  // Copy the manifests to the bastion
  // Copy the manifests to the bastion
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
        READY=""
        for i in $(seq 1 18); do
          if gcloud compute ssh ${var.ssh_user_bastion}@${var.bastion_hostname} --command uptime; then
            READY="yes"
            break;
          fi
          echo "Waiting for ${var.bastion_hostname} to initialize..."
          sleep 10;
        done

        if [[ -z $READY ]]; then
          echo "${var.bastion_hostname} failed to start in time."
          echo "Please verify that the instance starts and then re-run `terraform apply`"
          exit 1
        fi

        gcloud compute  --project ${var.project} scp --zone ${var.zone} --recurse ../manifests ${var.ssh_user_bastion}@${var.bastion_hostname}:
EOF

}
}