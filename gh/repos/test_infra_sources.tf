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

data "terraform_remote_state" "deploy-cf-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/deploy-cf-test-infra"
  }
}

data "terraform_remote_state" "get-gke-cred-test-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/get-gke-cred-test-infra"
  }
}

data "terraform_remote_state" "get-secretmanager-secrets-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/get-secretmanager-secrets-infra"
  }
}

data "terraform_remote_state" "deploy-appengine-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/deploy-appengine-infra"
  }
}

data "terraform_remote_state" "deploy-cloudrun-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/deploy-cloudrun-infra"
  }
}

data "terraform_remote_state" "upload-cloud-storage-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/upload-cloud-storage-infra"
  }
}

data "terraform_remote_state" "deploy-workflow-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/deploy-workflow-infra"
  }
}

data "terraform_remote_state" "setup-sdk-infra" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/setup-sdk-infra"
  }
}

data "terraform_remote_state" "actions-utils" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/actions-utils"
  }
}

data "terraform_remote_state" "auth" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/auth"
  }
}

data "terraform_remote_state" "ssh-compute" {
  backend = "gcs"
  config = {
    bucket = "actions-infra-tfstate-b4fa"
    prefix = "state/ssh-compute"
  }
}
