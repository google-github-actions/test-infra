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
  version = "~> 14.0"

  project_id = var.gcp_project

  activate_apis = [
    "secretmanager.googleapis.com",
  ]
}

resource "google_secret_manager_secret" "secret" {
  project   = module.project-services.project_id
  secret_id = "get-secretmanager-secrets-test-secret"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = "my super secret data"
}

resource "google_service_account" "get-secretmanager-secrets-sa" {
  account_id   = var.get_secretmanager_secrets_it_sa_name
  display_name = var.get_secretmanager_secrets_it_sa_name
}

resource "google_secret_manager_secret_iam_member" "access-secret" {
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.get-secretmanager-secrets-sa.email}"
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.get-secretmanager-secrets-sa.name
}
