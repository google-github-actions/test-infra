# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "ssh-compute" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "ssh-compute"
  repo_description  = "A GitHub Action to SSH into a Google Compute Engine instance."
  repo_homepage_url = "https://cloud.google.com/compute"
  repo_topics = concat([
    "compute-engine",
    "gce",
    "google-cloud-compute",
    "google-compute-engine",
  ], local.common_topics)

  repo_secrets = {
    // TODO(sethvargo): remove after migrating to variables
    "VM_NAME" : google_compute_instance.ssh-compute.instance_id
    "VM_ZONE" : google_compute_instance.ssh-compute.zone

    "VM_PRIVATE_KEY" : tls_private_key.ssh-compute.private_key_openssh
  }

  repo_variables = {
    "VM_NAME" : google_compute_instance.ssh-compute.instance_id
    "VM_ZONE" : google_compute_instance.ssh-compute.zone
  }

  depends_on = [
    google_project_service.services,
  ]
}

# Give the custom service account permissions to SSH into the VM.
resource "google_project_iam_member" "ssh-compute" {
  for_each = toset([
    "roles/compute.instanceAdmin.v1",
    "roles/compute.osLogin",
  ])

  project = data.google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${module.ssh-compute.service_account_email}"
}

resource "tls_private_key" "ssh-compute" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_subnetwork" "ssh-compute" {
  name          = "ssh-compute"
  ip_cidr_range = "10.127.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.network.id

  private_ip_google_access = true
}

resource "google_service_account" "ssh-compute-vm" {
  account_id   = "ssh-compute-vm"
  display_name = "ssh-compute-vm"
  description  = "Underlying VM service account for ssh-compute"
}

# Grant the custom service account permissions to impersonate the runtime VM
# service account (required for IAP).
resource "google_service_account_iam_member" "ssh-compute-runtime-impersonate" {
  service_account_id = google_service_account.ssh-compute-vm.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.ssh-compute.service_account_email}"
}

resource "google_project_iam_member" "ssh-compute-vm" {
  project = data.google_project.project.project_id
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.ssh-compute-vm.email}"
}

resource "google_compute_instance" "ssh-compute" {
  name         = "ssh-compute"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  # tag for internal firewall policies to allow iap
  tags = ["allow-iap"]

  can_ip_forward            = true
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ssh-compute.id
  }

  service_account {
    email  = google_service_account.ssh-compute-vm.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}

resource "google_compute_firewall" "ssh-compute-iap" {
  name    = "ssh-compute-iap"
  network = google_compute_network.network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # This is the netblock needed to forward to the instances:
  # https://cloud.google.com/iap/docs/using-tcp-forwarding#before_you_begin
  source_ranges = ["35.235.240.0/20"]

  target_service_accounts = [google_service_account.ssh-compute-vm.email]
}

resource "google_iap_tunnel_instance_iam_member" "ssh-compute-iap" {
  instance = google_compute_instance.ssh-compute.name
  zone     = google_compute_instance.ssh-compute.zone
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "serviceAccount:${module.ssh-compute.service_account_email}"

  depends_on = [
    google_project_service.services["iap.googleapis.com"]
  ]
}
