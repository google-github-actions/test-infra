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
  version = "~> 2.0"

  project_id  = var.gcp_project
  pool_id     = "test-sm-pool"
  provider_id = "test-sm-gh-provider"
  sa_mapping = {
    (google_service_account.get-secretmanager-secrets-sa.account_id) = {
      sa_name   = google_service_account.get-secretmanager-secrets-sa.name
      attribute = "attribute.repository/google-github-actions/get-secretmanager-secrets"
    }
  }
}
