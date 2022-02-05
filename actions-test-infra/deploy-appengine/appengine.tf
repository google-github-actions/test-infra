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
    "appengine.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ]
}

resource "google_app_engine_application" "app" {
  location_id = var.gcp_region
  project     = module.project-services.project_id
}

# Create the service account.
resource "google_service_account" "appengine-deploy-sa" {
  account_id   = var.appengine_deploy_it_sa_name
  display_name = var.appengine_deploy_it_sa_name
  project      = module.project-services.project_id
}
# Assign roles
resource "google_project_iam_member" "app-engine-deploy" {
  project = var.gcp_project
  role    = "roles/appengine.appAdmin"
  member  = "serviceAccount:${google_service_account.appengine-deploy-sa.email}"
}
resource "google_project_iam_member" "storage-admin" {
  project = var.gcp_project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.appengine-deploy-sa.email}"
}
resource "google_project_iam_member" "cloud-build-editor" {
  project = var.gcp_project
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.appengine-deploy-sa.email}"
}

# Allow deploy appengine SA to use app engine default sa
data "google_app_engine_default_service_account" "default" {
  project = var.gcp_project
}
resource "google_service_account_iam_member" "appengine-default-sa-user" {
  service_account_id = data.google_app_engine_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.appengine-deploy-sa.email}"
}

# Create key
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.appengine-deploy-sa.name
}
