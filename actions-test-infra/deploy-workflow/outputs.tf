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
  secrets = {
    "DEPLOY_WORKFLOW_CRED_SA_EMAIL" : google_service_account.deploy-workflow-cred-it-sa.email,
    "DEPLOY_WORKFLOW_CRED_SA_KEY_JSON" : base64decode(google_service_account_key.key.private_key),
    "DEPLOY_WORKFLOW_CRED_SA_KEY_B64" : google_service_account_key.key.private_key,
  }
}

# <k,v> pair of secrets for repo
output "secrets" {
  value     = local.secrets
  sensitive = true
}
