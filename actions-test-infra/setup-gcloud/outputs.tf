/*
 * Copyright 2022 Google LLC
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
    "PROJECT_ID" : var.gcp_project,

    "SAKE_PROJECT_ID" : var.gcp_project,
    "SAKE_SERVICE_ACCOUNT_EMAIL" : google_service_account.setup-gcloud.email,
    "SAKE_SERVICE_ACCOUNT_KEY_JSON" : google_service_account_key.setup-gcloud.private_key,

    "WIF_PROVIDER_NAME" : module.oidc.provider_name,
    "WIF_PROJECT_ID" : var.gcp_project,
    "WIF_SERVICE_ACCOUNT_EMAIL" : google_service_account.setup-gcloud.email,
  }
}

output "secrets" {
  value     = local.secrets
  sensitive = true
}
