# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Setting local variables
locals {
  iam_lnd = {
    "roles/bigquerydatatransfer.serviceAgent" = [
      module.land-sa-0.iam_email
    ]
    "roles/bigquery.admin" = [
      module.land-sa-0.iam_email
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      module.land-sa-0.iam_email
    ]
  }
}

# Defining the project that will host the Data Clean Room
module "land-project" {
  source          = "../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.landing
    : "${var.project_config.project_ids.landing}${local.project_suffix}"
  )
  iam = (
    var.project_config.billing_account_id == null ? {} : local.iam_lnd
  )
  services = [
    "bigquerydatatransfer.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "iam.googleapis.com",
    "analyticshub.googleapis.com",
  ]
}

# Defining the service account that will be used by the Data Clean Room
module "land-sa-0" {
  source       = "../modules/iam-service-account"
  project_id   = module.land-project.project_id
  prefix       = var.prefix
  name         = "lnd-sa-0"
  display_name = "DataCleanRoom zone service account."
}
