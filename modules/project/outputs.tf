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

output "service_account_email" {
  value = google_service_account.account.email
}

output "service_account_name" {
  value = google_service_account.account.name
}

output "workload_identity_pool_name" {
  value = google_iam_workload_identity_pool.pool.name
}

output "workload_identity_provider_name" {
  value = google_iam_workload_identity_pool_provider.provider.name
}

output "iam_safe_repo_name" {
  value = local.iam_safe_repo_name
}
