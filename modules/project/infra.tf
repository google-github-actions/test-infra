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

locals {
  # iam_safe_repo_name is the prefixed and randomly-suffixed name that includes
  # the repo name. These values must be no more than 32 characters. The random
  # characters ensure uniquness and is required for destroy/re-create workflows
  # since many IAM resources are tombstoned.
  iam_safe_repo_name = "gh-${substr(lower(var.repo_name), 0, 30 - 4 - length(random_id.random.hex))}-${random_id.random.hex}"
}

resource "random_id" "random" {
  byte_length = 2
}

resource "google_service_account" "account" {
  account_id   = local.iam_safe_repo_name
  display_name = "${var.repo_name} service account"
  description  = "Integration tests for ${var.github_organization_name}/${var.repo_name}"
}

resource "google_service_account_iam_member" "self" {
  service_account_id = google_service_account.account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.account.email}"
}

resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = local.iam_safe_repo_name
  display_name              = substr(lower(var.repo_name), 0, 32)
  description               = "WIF authentication from ${var.github_organization_name}/${var.repo_name}"
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "provider"
  display_name                       = substr(lower(var.repo_name), 0, 32)
  description                        = "WIF authentication from ${var.github_organization_name}/${var.repo_name}"

  attribute_mapping = {
    "google.subject" : "assertion.sub"
    "attribute.actor" : "assertion.actor"
    "attribute.aud" : "assertion.aud"
    "attribute.event_name" : "assertion.event_name"
    "attribute.repository_id" : "assertion.repository_id"
    "attribute.repository_owner_id" : "assertion.repository_owner_id"
    "attribute.workflow" : "assertion.workflow"
  }

  # We create conditions based on ID instead of name to prevent name hijacking
  # or squatting attacks.
  #
  # We also prevent pull_request_target, since that runs arbitrary code:
  #   https://securitylab.github.com/research/github-actions-preventing-pwn-requests/
  attribute_condition = "attribute.event_name != \"pull_request_target\" && attribute.repository_owner_id == \"${var.github_organization_id}\" && attribute.repository_id == \"${github_repository.repo.repo_id}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif" {
  service_account_id = google_service_account.account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/*"
}
