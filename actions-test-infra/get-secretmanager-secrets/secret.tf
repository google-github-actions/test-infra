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
    "secretmanager.googleapis.com",
  ]
}

resource "google_secret_manager_secret" "secret" {
  provider  = google-beta
  project   = module.project-services.project_id
  secret_id = "get-secretmanager-secrets-test-secret"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "version" {
  provider    = google-beta
  secret      = google_secret_manager_secret.secret.id
  secret_data = "my super secret data"
}

resource "google_service_account" "get-secretmanager-secrets-sa" {
  provider     = google-beta
  account_id   = var.get_secretmanager_secrets_it_sa_name
  display_name = var.get_secretmanager_secrets_it_sa_name
}

resource "google_secret_manager_secret_iam_member" "access-secret" {
  provider  = google-beta
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.gcp_project}@appspot.gserviceaccount.com"
}

resource "google_service_account_key" "key" {
  provider           = google-beta
  service_account_id = google_service_account.get-secretmanager-secrets-sa.name
}
