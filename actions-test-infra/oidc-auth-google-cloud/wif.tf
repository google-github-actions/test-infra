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

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 9.0"

  project_id = var.gcp_project
  activate_apis = [
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
  ]
}

module "oidc" {
  source  = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  version = "~> 1.1"

  project_id  = var.gcp_project
  pool_id     = "test-pool"
  provider_id = "test-gh-provider"
  sa_mapping = {
    (google_service_account.oidc-auth-test-sa.account_id) = {
      sa_name   = google_service_account.oidc-auth-test-sa.name
      attribute = "attribute.repository/sethvargo/oidc-auth-google-cloud"
    }
  }
}
