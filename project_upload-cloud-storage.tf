# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "upload-cloud-storage" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "upload-cloud-storage"
  repo_description  = "A GitHub Action for uploading files to a Google Cloud Storage (GCS) bucket."
  repo_homepage_url = "https://cloud.google.com/"
  repo_topics = concat([
    "gcs",
    "google-cloud-storage",
  ], local.common_topics)

  repo_secrets = {
  }

  repo_collaborators = {
    users = {
      "google-github-actions-bot" : "triage"
    }

    teams = {
      "maintainers" : "admin"
    }
  }

  depends_on = [
    google_project_service.services,
  ]
}


resource "google_storage_bucket" "upload-cloud-storage-bucket" {
  name          = module.upload-cloud-storage.iam_safe_repo_name
  location      = "us-central1"
  force_destroy = true

  depends_on = [
    google_project_service.services["storage.googleapis.com"],
    google_project_service.services["storage-api.googleapis.com"],
  ]
}

resource "google_storage_bucket_iam_member" "upload-cloud-storage" {
  bucket = google_storage_bucket.upload-cloud-storage-bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.upload-cloud-storage.service_account_email}"
}
