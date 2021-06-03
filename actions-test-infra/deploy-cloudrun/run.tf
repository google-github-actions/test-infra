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
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}
# Create the service account.
resource "google_service_account" "deploy-cloudrun-sa" {
  account_id   = var.deploy_cloudrun_it_sa_name
  display_name = var.deploy_cloudrun_it_sa_name
}

# Assign the Cloud Run Admin role
resource "google_project_iam_member" "cloud-run-role" {
  project = var.gcp_project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.deploy-cloudrun-sa.email}"
}

data "google_project" "project" {
  project_id = var.gcp_project
}

# Assign the IAM Service Account User role on the Cloud Run runtime service account:
resource "google_service_account_iam_binding" "service-account-role" {
  service_account_id = "projects/${var.gcp_project}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  members            = ["serviceAccount:${google_service_account.deploy-cloudrun-sa.email}"]
}

# Create outputs
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.deploy-cloudrun-sa.name
}
