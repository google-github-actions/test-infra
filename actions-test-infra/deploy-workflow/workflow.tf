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
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 10.0"

  project_id = var.gcp_project

  activate_apis = [
    "workflows.googleapis.com",
  ]
}

# Create the service account.
resource "google_service_account" "deploy-workflow-cred-it-sa" {
  project      = module.project-services.project_id
  account_id   = var.deploy_workflow_cred_it_sa_name
  display_name = var.deploy_workflow_cred_it_sa_name
}

# Assign the Workflows Admin IAM role to the service account.
resource "google_project_iam_member" "deploy-workflow-cred-admin" {
  role   = "roles/workflows.admin"
  member = "serviceAccount:${google_service_account.deploy-workflow-cred-it-sa.email}"
}

# Create service account key.
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.deploy-workflow-cred-it-sa.name
}
