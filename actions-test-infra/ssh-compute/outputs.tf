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
  secrets = {
    "SSH_COMPUTE_SA_EMAIL" : google_service_account.ssh-sa.email,
    "SSH_COMPUTE_SA_KEY_JSON" : base64decode(google_service_account_key.key.private_key),
    "SSH_COMPUTE_SA_KEY_B64" : google_service_account_key.key.private_key,
    "SSH_COMPUTE_IAP_VM_NAME" : module.ssh-iap-vm.hostname,
    "SSH_COMPUTE_EXTERNAL_VM_NAME" : google_compute_instance.ssh-external-vm.name
  }
}

# <k,v> pair of secrets for repo
output "secrets" {
  value     = local.secrets
  sensitive = true
}
