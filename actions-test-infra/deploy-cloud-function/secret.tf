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

resource "google_secret_manager_secret" "secret" {
  provider  = google-beta
  project   = module.project-services.project_id
  secret_id = "deploy-cloud-function-test-secret"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "version" {
  provider    = google-beta
  secret      = google_secret_manager_secret.secret.id
  secret_data = "my super secret data"
}

# Grant the default runtime service account permissions.
resource "google_secret_manager_secret_iam_member" "default-access-secret" {
  provider  = google-beta
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.gcp_project}@appspot.gserviceaccount.com"
}

# Grant the custom runtime service account permissions.
resource "google_secret_manager_secret_iam_member" "custom-access-secret" {
  provider  = google-beta
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.deploy-cf-it-sa.email}"
}
