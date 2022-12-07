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

locals {
  gh_org        = "google-github-actions"
  common_topics = ["actions", "github-actions", "gcp", "google-cloud", "google-cloud-platform"]
  repos = [
    {
      name : "setup-gcloud",
      description : "A GitHub Action for configuring the Google Cloud SDK.",
      topics : concat(local.common_topics, ["gcloud", "gcloud-sdk", "gcloud-cli", "bq", "gsutil"]),
      templated : false,
      secrets : data.terraform_remote_state.setup-gcloud-infra.outputs.secrets,
    },
    {
      name : "test-infra",
      description : "Test infrastructure for Google Github Actions.",
      templated : false
    },
    {
      name : "deploy-cloudrun",
      description : "This action deploys your container image to Cloud Run.",
      templated : false,
      topics : concat(local.common_topics, ["cloud-run", "google-cloud-run"]),
      secrets : data.terraform_remote_state.deploy-cloudrun-infra.outputs.secrets
    },
    {
      name : "deploy-cloud-functions",
      description : "This action deploys your function source code to Cloud Functions.",
      templated : false,
      topics : concat(local.common_topics, ["gcf", "google-cloud-functions"]),
      secrets : data.terraform_remote_state.deploy-cf-infra.outputs.secrets
    },
    {
      name : "get-gke-credentials",
      description : "This action configures authentication to a GKE cluster.",
      templated : false,
      topics : concat(local.common_topics, ["gke", "google-kubernetes-engine", "kubernetes"]),
      secrets : data.terraform_remote_state.get-gke-cred-test-infra.outputs.secrets
    },
    {
      name : "get-secretmanager-secrets",
      description : "This action fetches secrets from Secret Manager and makes them available to later build steps via outputs.",
      templated : false,
      topics : concat(local.common_topics, ["secrets", "secret-manager", "google-secret-manager"]),
      secrets : data.terraform_remote_state.get-secretmanager-secrets-infra.outputs.secrets
    },
    {
      name : "upload-cloud-storage",
      description : "This action uploads files/folders to a Google Cloud Storage (GCS) bucket.",
      templated : false,
      topics : concat(local.common_topics, ["gcs", "google-cloud-storage"]),
      secrets : data.terraform_remote_state.upload-cloud-storage-infra.outputs.secrets
    },
    {
      name : "deploy-appengine",
      description : "This action deploys your source code to App Engine.",
      templated : false,
      topics : concat(local.common_topics, ["gae", "google-app-engine", "google-appengine"]),
      secrets : data.terraform_remote_state.deploy-appengine-infra.outputs.secrets
    },
    {
      name : "deploy-workflow",
      description : "This action deploys your Google Cloud Workflow",
      templated : false,
      topics : concat(local.common_topics, ["workflows", "google-cloud-workflows"]),
      secrets : data.terraform_remote_state.deploy-workflow-infra.outputs.secrets
    },
    {
      name : "release-please-action",
      description : "automated releases based on conventional commits",
      templated : false,
      status_checks : ["cla/google", "test (12)"]
    },
    {
      name : ".github",
      description : "Default files for google-github-actions",
      templated : false
    },
    {
      name : "actions-docs",
      description : "Generate documentation for GitHub Actions",
      templated : false
    },
    {
      name : "setup-cloud-sdk",
      description : "NPM package for interacting with Google Cloud SDK",
      templated : false,
      secrets : data.terraform_remote_state.setup-sdk-infra.outputs.secrets
    },
    {
      name : "actions-utils",
      description : "NPM package for Google GitHub Actions utils",
      templated : false
    },
    {
      name : "ssh-compute",
      description : "This action allows you to ssh into a Compute Engine instance.",
      templated : false,
      topics : concat(local.common_topics, ["gce", "compute-engine", "google-cloud-compute"]),
      secrets : data.terraform_remote_state.ssh-compute.outputs.secrets
    },
    {
      name : "auth",
      description : "GitHub Action for authenticating to Google Cloud with GitHub Actions OIDC tokens and Workload Identity Federation.",
      templated : false,
      topics : concat(local.common_topics, ["iam", "identity", "security", "authentication", "google-cloud-identity"]),
      delete_branch_on_merge : true,
      has_downloads : true,
      secrets : data.terraform_remote_state.auth.outputs.secrets
      status_checks : [
        "cla/google",
        "credentials_json (macos-latest)",
        "credentials_json (ubuntu-latest)",
        "credentials_json (windows-latest)",
        "unit",
        "workload_identity_federation (macos-latest)",
        "workload_identity_federation (ubuntu-latest)",
        "workload_identity_federation (windows-latest)",
      ]
    },
    {
      name : "example-workflows",
      description : "Repository to demonstrate example workflows.",
      templated : false,
      topics : concat(local.common_topics, ["examples", "starter-workflows"]),
      delete_branch_on_merge : true,
      status_checks : [
        "cla/google",
      ]
    },
    {
      name : "run-vertexai-notebook",
      description : "GitHub Action for running Google Cloud Vertex AI notebooks asynchronously.",
      templated : false,
      topics : concat(local.common_topics, ["machine-learning", "vertex-ai", "artificial-intelligence", "ml-notebooks"]),
      delete_branch_on_merge : true,
      status_checks : [
        "cla/google",
      ]
    },
    {
      name : "create-cloud-deploy-release",
      description : "This action creates a release for Cloud Deploy.",
      templated : false,
      topics : concat(local.common_topics, ["google-cloud-deploy","cloud-deploy","ci-cd"]),
      delete_branch_on_merge : true,
      status_checks : [
        "cla/google",
      ]
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
    status_checks : can(repo.status_checks) ? repo.status_checks : ["cla/google"]
    # set dependabot alerts, default to true
    vulnerability_alerts : can(repo.vulnerability_alerts) ? repo.vulnerability_alerts : true
    # require codeowner reviews, default to true
    require_code_owner_reviews : can(repo.require_code_owner_reviews) ? repo.require_code_owner_reviews : true
    # enfore admins
    enforce_admins : can(repo.enforce_admins) ? repo.enforce_admins : false
    # auto delete branch after merging PR
    delete_branch_on_merge : can(repo.delete_branch_on_merge) ? repo.delete_branch_on_merge : true
    # topics
    topics : can(repo.topics) ? repo.topics : null
    # has_downloads
    has_downloads : can(repo.has_downloads) ? repo.has_downloads : false
  } }
  gh_org                     = local.gh_org
  repo_name                  = each.key
  description                = each.value.description
  secrets                    = each.value.secrets
  status_checks              = each.value.status_checks
  vulnerability_alerts       = each.value.vulnerability_alerts
  require_code_owner_reviews = each.value.require_code_owner_reviews
  enforce_admins             = each.value.enforce_admins
  gha_bot_token              = data.google_secret_manager_secret_version.bot.secret_data
  delete_branch_on_merge     = each.value.delete_branch_on_merge
  topics                     = each.value.topics
  has_downloads              = each.value.has_downloads
  # if templated repo use google-github-actions-template
  template_repo_name = each.value.templated ? "google-github-actions-template" : ""
}
