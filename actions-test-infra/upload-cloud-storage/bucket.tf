/*
 * Copyright 2020 Google LLC
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
resource "google_project_service" "storage" {
  service = "storage-api.googleapis.com"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Create a test bucket.
resource "google_storage_bucket" "test-bucket" {
  name          = "upload-cloud-storage-it-bucket-${random_id.suffix.hex}"
  project       = google_project_service.storage.project
  force_destroy = true
}

# Declare a custom IAM role.
resource "google_project_iam_custom_role" "gcs-project-role" {
  role_id     = "GCSITIamRole"
  title       = "GCS IAM role for project access"
  description = "Bare minimum permissions for the upload-cloud-storage SA."
  project     = google_project_service.storage.project
  permissions = [
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.delete",
    "storage.buckets.get",
    "storage.buckets.list",
  ]
}

# Create the service account.
resource "google_service_account" "upload-cloud-storage-sa" {
  project      = google_project_service.storage.project
  account_id   = var.upload_cloud_storage_it_sa_name
  display_name = var.upload_cloud_storage_it_sa_name
}

# Assign the custom IAM role to the service account.
resource "google_project_iam_member" "upload-cloud-storage-access" {
  role   = google_project_iam_custom_role.gcs-project-role.id
  member = "serviceAccount:${google_service_account.upload-cloud-storage-sa.email}"
}

# Create service account key.
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.upload-cloud-storage-sa.name
}
