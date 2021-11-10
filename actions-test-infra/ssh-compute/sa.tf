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

# Enable necessary APIs.
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 9.0"

  project_id = var.gcp_project

  activate_apis = [
    "compute.googleapis.com",
    "iap.googleapis.com",
  ]
}

# Create the service account for test access.
resource "google_service_account" "ssh-sa" {
  project      = module.project-services.project_id
  account_id   = "test-ssh-sa"
  display_name = "test-ssh-sa"
}

# Assign the instance admin role to the service account to update keys and ssh.
resource "google_project_iam_member" "ssh-into-vms" {
  role   = "roles/compute.instanceAdmin.v1"
  member = "serviceAccount:${google_service_account.ssh-sa.email}"
}

# Create service account key.
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.ssh-sa.name
}
