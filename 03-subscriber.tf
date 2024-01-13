# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Setting local variables for IAM
locals {
  cur_services = [
    "bigquerydatatransfer.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "iam.googleapis.com",
    "analyticshub.googleapis.com",
  ]
  iam_cur = {
    "roles/bigquery.admin" = [
      module.cur-sa-0.iam_email
    ]
    "roles/analyticshub.viewer" = [
      module.cur-sa-0.iam_email
    ]
    "roles/analyticshub.subscriber" = [
      module.cur-sa-0.iam_email
    ]
   "roles/analyticshub.publisher" = [
      module.cur-sa-0.iam_email
    ]
  }
}

# Defining the project for the subscriber to the clean room
module "cur-project" {
  source          = "../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.curated
    : "${var.project_config.project_ids.curated}${local.project_suffix}"
  )
  iam = (
    var.project_config.billing_account_id != null ? {} : local.iam_cur
  )
  services = local.cur_services
  service_encryption_key_ids = {
    bq      = [var.service_encryption_keys.bq]
    storage = [var.service_encryption_keys.storage]
  }
}

module "cur-sa-0" {
  source       = "../modules/iam-service-account"
  project_id   = module.cur-project.project_id
  prefix       = var.prefix
  name         = "cur-sa-0"
  display_name = "Subscriber zone service account."
}

resource "google_project_iam_member" "iam-cur" {
  for_each = { for role, members in local.iam_cur : role => members }
  role     = each.key
  member   = each.value[0]
  project  = module.cur-project.project_id
  depends_on = [module.cur-sa-0]
}

# Subscribing to the clean room listing through an API call
resource "null_resource" "subscribe-listing" {
  provisioner "local-exec" {
    command = <<-EOF
      curl --request POST \
      'https://analyticshub.googleapis.com/v1beta1/projects/${module.land-project.number}/locations/${var.location}/dataExchanges/${google_bigquery_analytics_hub_data_exchange.data-exchange.data_exchange_id}/listings/${google_bigquery_analytics_hub_listing.dcr-listing.listing_id}:subscribe' \
      --header "Authorization: Bearer $(gcloud auth print-access-token)" \
      --header 'Accept: application/json' \
      --header 'Content-Type: application/json' \
      --data '{ "destinationDataset": { "datasetReference": { "datasetId": "subscribed_dataset", "projectId": "${module.cur-project.project_id}" }, "location": "${var.location}" } }' \
      --compressed
    EOF
  }
}