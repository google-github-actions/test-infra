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

module "oidc" {
  source  = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  version = "~> 3.0"

  project_id  = var.gcp_project
  pool_id     = "test-crun-pool"
  provider_id = "test-crun-gh-provider"
  sa_mapping = {
    (google_service_account.deploy-cloudrun-sa.account_id) = {
      sa_name   = google_service_account.deploy-cloudrun-sa.name
      attribute = "attribute.repository/google-github-actions/deploy-cloudrun"
    }
  }
}
