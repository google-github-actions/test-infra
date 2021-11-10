/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# VPC and subnet
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.0"

  project_id   = module.project-services.project_id
  network_name = "test-ssh-compute-net"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "test-ssh-compute-subnet"
      subnet_ip             = "10.127.0.0/20"
      subnet_region         = "us-central1"
      subnet_private_access = true
    }
  ]
}

# NAT for egress from VM without external IP
module "cloud-nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "~> 2.0"

  project_id    = module.project-services.project_id
  region        = "us-central1"
  router        = "ssh-compute-router"
  network       = module.vpc.network_self_link
  create_router = true
}

# VM with IAP setup
module "ssh-iap-vm" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "~> 4.0"

  network       = module.vpc.network_self_link
  subnet        = module.vpc.subnets_self_links[0]
  project       = module.project-services.project_id
  host_project  = module.project-services.project_id
  name          = "ssh-iap-vm"
  zone          = "us-central1-a"
  image_project = "debian-cloud"
  image_family  = "debian-10"
  machine_type  = "f1-micro"
  members       = ["serviceAccount:${google_service_account.ssh-sa.email}"]
}

# SA for VM with external IP
resource "google_service_account" "ssh-external-vm-sa" {
  project      = module.project-services.project_id
  account_id   = "ssh-external-vm"
  display_name = "ssh-external-vm"
}

# Assign the IAM Service Account User role on the VM SA:
resource "google_service_account_iam_member" "external-vm-user" {
  service_account_id = google_service_account.ssh-external-vm-sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ssh-sa.email}"
}

# VM with external IP
resource "google_compute_instance" "ssh-external-vm" {
  name         = "ssh-external-vm"
  project      = module.project-services.project_id
  machine_type = "f1-micro"
  zone         = "us-central1-a"
  metadata = {
    enable-oslogin = "TRUE"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = module.vpc.subnets_self_links[0]
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.ssh-external-vm-sa.email
    scopes = ["cloud-platform"]
  }
}

# FW rule allowing ingress on port 22 for SSH targeting external IP VM SA
resource "google_compute_firewall" "rules" {
  project     = module.project-services.project_id
  name        = "allow-ssh-ingress"
  network     = module.vpc.network_name
  description = "Allow SSH to external VM"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_service_accounts = [google_service_account.ssh-external-vm-sa.email]
}
