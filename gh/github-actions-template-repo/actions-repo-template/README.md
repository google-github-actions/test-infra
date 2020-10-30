<!--
Copyright 2019 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# verb-resource

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus condimentum rhoncus est volutpat venenatis. Fusce semper, sapien ut venenatis pellentesque, lorem dui aliquam sapien, non pharetra diam neque id mi. Suspendisse sollicitudin, metus ut gravida semper, nunc ipsum ullamcorper nunc, ut maximus nulla nunc dignissim justo. Duis nec nisi leo. Proin tristique massa mi, imperdiet tempus nibh vulputate quis. Morbi sagittis eget neque sagittis egestas. Quisque viverra arcu a cursus dignissim.

## Prerequisites

-   This action requires Google Cloud credentials that are authorized to access
    the secrets being requested. See the Authorization section below for more
    information.


## Usage

```yaml
steps:
- id: foo
  uses: verb-resource@main

```

## Inputs

-   `bar`: (Required) In aliquam, mi ut laoreet varius, ex ante posuere justo, eget aliquam magna metus id purus. Aenean convallis sem ac purus bibendum, sit amet mattis augue fermentum.

-   `baz`: (Optional) uisque cursus posuere mi, vitae vestibulum purus egestas eget. Nunc eu sagittis est, at elementum leo.


## Outputs
Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. 

## Authorization

There are a few ways to authenticate this action. The caller must have
permissions to access the secrets being requested.

### Via the setup-gcloud action

You can provide credentials using the [setup-gcloud][setup-gcloud] action:

```yaml
- uses: GoogleCloudPlatform/github-actions/setup-gcloud@main
  with:
    export_default_credentials: true
```

The advantage of this approach is that it authenticates all future actions. A
disadvantage of this approach is that downloading and installing gcloud may be
heavy for some use cases.

### Via credentials

You can provide [Google Cloud Service Account JSON][sa] directly to the action
by specifying the `credentials` input. First, create a [GitHub
Secret][gh-secret] that contains the JSON content, then import it into the
action:

```yaml
- id: secrets
  uses: GoogleCloudPlatform/github-actions/get-secretmanager-secrets@main
  with:
    credentials: ${{ secrets.gcp_credentials }}
    secrets: |-
      # ...
```

### Via Application Default Credentials

If you are hosting your own runners, **and** those runners are on Google Cloud,
you can leverage the Application Default Credentials of the instance. This will
authenticate requests as the service account attached to the instance. **This
only works using a custom runner hosted on GCP.**

```yaml
- id: secrets
  uses: GoogleCloudPlatform/github-actions/get-secretmanager-secrets@main
```

The action will automatically detect and use the Application Default
Credentials.


[sa]: https://cloud.google.com/iam/docs/creating-managing-service-accounts
[gh-runners]: https://help.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners
[gh-secret]: https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets
[setup-gcloud]: ../setup-gcloud