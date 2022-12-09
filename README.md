# Test Infrastructure

This repository defines the GitHub repository configurations and test
infrastructure for testing GitHub Actions.


## Principles

The test infrastructure uses the following principles:

-   There is value in reduction of choice and sane defaults. We minimize the
    number of Terraform variables and conditionals to optimize for readability.

-   Only introduce Terraform variables when they are explicitly needed and have
    sane default values.

-   Minimize dependencies on external modules unless they add significant value
    or mask significant complexity.


## Design

Each project has its own Google Cloud Service Account and Workload Identity
Federation Provider for authentication and authorization. Repositories are
automatically configured with GitHub Secrets that inject these configuration
variables as:

-   `PROJECT_ID`
-   `SERVICE_ACCOUNT_EMAIL`
-   `WIF_PROVIDER_NAME`

Authentication to the WIF provider is guarded by the organization ID (forks
won't have access) and the numeric repository ID. Using IDs prevents against
replay naming attacks.

Additionally, there is an organization secret (accessible to all repos)
`ACTIONS_BOT_TOKEN` which is a GitHub Personal Access Token for our GitHub
Actions bot. This is largely for authoring commits, since the Google CLA cannot
be signed by the GitHub Actions bot.

Additional per-repository secrets and configuration should reside inside the
project Terraform file.


## Setup

1.  (First time only) Create a `terraform.tfvars` file with the following
    information:

    ```hcl
    # This is the project ID of your Google Cloud project. You must create the Google Cloud project in advance.
    project_id = "TODO"

    # This is the GitHub organization name.
    github_organization_name = "TODO"
    ```

1.  Install and configure the Google Cloud SDK, and authenticate as a principle
    that has permissions to manage resources in the given "project_id".

    ```sh
    gcloud auth login --update-adc
    ```

1.  Create a GitHub Personal Access Token with permissions to administer
    repositories and configuration over the target organization defined in
    "github_organization_name".

    > [Creating Person Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) in the GitHub documentation.

    Save this as the environment variable `GITHUB_TOKEN`:

    ```shell
    export GITHUB_TOKEN="TODO"
    ```

    If you start a new shell, you will need to export the token again. For this
    reason, we recommend storing the token in a password manager so you do not
    have to generate a new one each time.


## Creating new repos

After following the internal team documentation to get legal approval for a new
repository, follow these steps to bootstrap a new project.

1.  Create a new Terraform file with the naming convention:

    ```text
    project_<reponame>.tf
    ```

1.  Define the `project` module, or copy-paste an existing project as a
    skeleton. Make sure you properly define the repository name, description,
    labels, and ACLs. At minimum, you must add the following ACLs:

    ```hcl
    repo_collaborators = {
      users = {
        "google-github-actions-bot" : "triage"
      }

      teams = {
        "maintainers" : "admin"
      }
    }
    ```

1.  Add any other resources the project will need, such as secrets or IAM
    permissions. Note that the `project` module automatically configures
    Workload Identity Federation and provides a service account email as an
    output.

1.  If you need to enable any new Google Cloud _services_, add them in the
    `main.tf` file.

1.  Since Google's internal system will have already created the repository, you
    must import it into the Terraform state. You only need to do this the first time.

    ```shell
    terraform import module.<repo_name>.github_repository.repo <repo_name>
    ```

    For example, to import the `setup-gcloud` repo:

    ```shell
    terraform import module.setup-gcloud.github_repository.repo setup-gcloud
    ```

1.  Run `terraform apply` to provision the changes. To limit to just your new
    project, run a targeted apply:

    ```shell
    terraform apply -target module.<repo_name>
    ```


## Rotating Service Account Keys

Only a few repositories rely on Service Account Key JSON files, mostly to test
that the GitHub Action works with exported keys. To rotate all the keys, run
this script:

```shell
./scripts/rotate-service-account-keys
```

The script searches for and taints all `google_service_account_key` resources
and runs `terraform apply`.
