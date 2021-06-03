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
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

# Create a test pubsub topic.
resource "google_pubsub_topic" "test-topic" {
  name = var.deploy_cf_test_topic
}

# Create the service account.
resource "google_service_account" "deploy-cf-it-sa" {
  project      = module.project-services.project_id
  account_id   = var.deploy_cf_it_sa_name
  display_name = var.deploy_cf_it_sa_name
}

# Assign the CF Admin IAM role to the service account.
resource "google_project_iam_member" "deploy-cf-admin" {
  role   = "roles/cloudfunctions.admin"
  member = "serviceAccount:${google_service_account.deploy-cf-it-sa.email}"
}

# Assign the IAM Service Account User role on the CF runtime service account:
resource "google_service_account_iam_member" "cf-default-sa" {
  service_account_id = "projects/${var.gcp_project}/serviceAccounts/${var.gcp_project}@appspot.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy-cf-it-sa.email}"
}

# Create service account key.
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.deploy-cf-it-sa.name
}
