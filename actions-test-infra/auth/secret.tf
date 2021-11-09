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

# create a test secret resource that the SA has permissions to access
resource "google_service_account" "oidc-auth-test-sa" {
  provider   = google-beta
  account_id = "oidc-auth-infra-sa"
}

resource "google_secret_manager_secret" "secret" {
  provider  = google-beta
  project   = module.project-services.project_id
  secret_id = "oidc-auth-test-secret"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "version" {
  provider    = google-beta
  secret      = google_secret_manager_secret.secret.id
  secret_data = "my super secret data"
}

resource "google_secret_manager_secret_iam_member" "access-secret" {
  provider  = google-beta
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.oidc-auth-test-sa.email}"
}

resource "google_secret_manager_secret_iam_member" "access-secret-key" {
  provider  = google-beta
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.auth-key.email}"
}
