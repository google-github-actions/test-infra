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

resource "github_repository" "repo" {
  name         = var.repo_name
  description  = var.repo_description
  homepage_url = var.repo_homepage_url
  topics       = var.repo_topics
  visibility   = var.repo_visibility

  allow_auto_merge            = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_squash_merge          = true
  delete_branch_on_merge      = true
  squash_merge_commit_message = "PR_BODY"
  squash_merge_commit_title   = "PR_TITLE"

  has_downloads        = false
  has_issues           = true
  has_projects         = false
  has_wiki             = false
  is_template          = false
  vulnerability_alerts = true
}

resource "github_branch_protection" "protection" {
  repository_id                   = github_repository.repo.node_id
  pattern                         = "main"
  require_conversation_resolution = true
  required_linear_history         = true

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    dismiss_stale_reviews      = false
    require_code_owner_reviews = true
  }
}

resource "github_repository_tag_protection" "protection" {
  repository = github_repository.repo.name
  pattern    = "v*"
}

resource "github_actions_secret" "secrets" {
  for_each = merge(
    {
      "PROJECT_ID" : google_service_account.account.project
      "SERVICE_ACCOUNT_EMAIL" : google_service_account.account.email
      "WIF_PROVIDER_NAME" : google_iam_workload_identity_pool_provider.provider.name
    },
    var.repo_secrets,
  )

  repository      = github_repository.repo.name
  secret_name     = each.key
  plaintext_value = each.value
}

resource "github_repository_collaborator" "users" {
  for_each = var.repo_collaborators.users

  repository = github_repository.repo.name
  username   = each.key
  permission = each.value
}

resource "github_team_repository" "teams" {
  for_each = var.repo_collaborators.teams

  repository = github_repository.repo.name
  team_id    = each.key
  permission = each.value
}
