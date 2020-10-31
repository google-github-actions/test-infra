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

locals {
  gh_org = "google-github-actions"
  repos = [
    {
      name : "test-infra",
      description : "Test infrastructure for Google Github Actions.",
      templated : false
    },
    {
      name : "deploy-cloudrun",
      description : "This action deploys your container image to Cloud Run.",
      templated : false,
      secrets : data.terraform_remote_state.deploy-cloudrun-infra.outputs.secrets
    },
    {
      name : "deploy-cloud-functions",
      description : "This action deploys your function source code to Cloud Functions.",
      templated : false,
      secrets : data.terraform_remote_state.deploy-cf-infra.outputs.secrets
    },
    {
      name : "get-gke-credentials",
      description : "This action configures authentication to a GKE cluster.",
      templated : false,
      secrets : data.terraform_remote_state.get-gke-cred-test-infra.outputs.secrets
    },
    {
      name : "get-secretmanager-secrets",
      description : "This action fetches secrets from Secret Manager and makes them available to later build steps via outputs.",
      templated : false,
      secrets : data.terraform_remote_state.get-secretmanager-secrets-infra.outputs.secrets
    },
    {
      name : "upload-cloud-storage",
      description : "This action uploads files/folders to a Google Cloud Storage (GCS) bucket.",
      templated : false,
      secrets : data.terraform_remote_state.upload-cloud-storage-infra.outputs.secrets
    },
    {
      name : "deploy-appengine",
      description : "This action deploys your source code to App Engine.",
      templated : false,
      secrets : data.terraform_remote_state.deploy-appengine-infra.outputs.secrets
    },
  ]
}

module "repos" {
  source = "../modules/actions-repo"
  for_each = { for repo in local.repos : repo.name => {
    description : repo.description,
    # by default use templated repos,if not set to false
    templated : can(repo.templated) ? repo.templated : true
    # create secrets if set
    secrets : can(repo.secrets) ? repo.secrets : {}
    # create status_checks if set
    status_checks : can(repo.status_checks) ? repo.status_checks : []
  } }
  gh_org        = local.gh_org
  repo_name     = each.key
  description   = each.value.description
  secrets       = each.value.secrets
  status_checks = each.value.status_checks
  # if templated repo use google-github-actions-template
  template_repo_name = each.value.templated ? "google-github-actions-template" : ""
}
