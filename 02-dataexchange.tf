# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Creating a BigQuery dataset to host the sample data set "thelook_ecommerce"
module "thelook-dataset" {
  source         = "../modules/bigquery-dataset"
  project_id     = module.land-project.project_id
  id             = var.thelook_dataset
  location       = var.location
}

# Setting up the transfer of the sample data set "thelook_ecommerce" from the public project "bigquery-public-data" to the Data Clean Room project
# Verify if transfer is working in https://console.cloud.google.com/bigquery/transfers
resource "google_bigquery_data_transfer_config" "thelook-transfer" {
  depends_on = [module.land-project, module.land-sa-0, module.thelook-dataset]
  project = module.land-project.project_id
  display_name           = "thelook-transfer"
  location               = var.location
  schedule               = "every day 01:00"
  data_source_id         = "cross_region_copy"
  destination_dataset_id = module.thelook-dataset.dataset_id
  service_account_name   = module.land-sa-0.email
  params = {
    source_dataset_id       = "thelook_ecommerce"
    source_project_id       = "bigquery-public-data"
  }
}

# Creating a Dataset to host the Data Clean Room
module "dcr-dataset" {
  source         = "../modules/bigquery-dataset"
  project_id     = module.land-project.project_id
  id             = var.dcr_dataset
  location       = var.location
}

# Creating a view with a privacy policy - this makes the dataexchange behave like a Data Clean Room 
resource "null_resource" "dcr-view" {
  depends_on = [google_bigquery_data_transfer_config.thelook-transfer]
  provisioner "local-exec" {
    command = "bq query --project_id ${module.land-project.project_id} --nouse_legacy_sql 'CREATE OR REPLACE VIEW `${module.land-project.project_id}.dcr_dataset.dcr_view` OPTIONS (privacy_policy= \"{\\\"aggregation_threshold_policy\\\": {\\\"threshold\\\" : 20, \\\"privacy_unit_columns\\\": \\\"id\\\"}}\") AS ( SELECT id, age, email, state, city FROM `${module.land-project.project_id}.${module.thelook-dataset.dataset_id}.users` )';"
  }
}

# Creating a Data Exchange to host the Data Clean Room
# This is while the Data Clean Room is in Alpha as the API is not available/documented 
resource "google_bigquery_analytics_hub_data_exchange" "data-exchange" {
  project = module.land-project.project_id
  location         = var.location
  data_exchange_id = var.data_exchange
  display_name     = var.data_exchange
  description      = "Demo Data Clean Room ${var.data_exchange}"
}

resource "google_bigquery_analytics_hub_listing" "dcr-listing" {
  depends_on = [google_bigquery_analytics_hub_data_exchange.data-exchange]
  project = module.land-project.project_id
  location         = var.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data-exchange.data_exchange_id
  listing_id       = var.dcr_listing
  display_name     = var.dcr_listing
  description      = "Listing for the ${var.data_exchange} clean room"

  bigquery_dataset {
    dataset = module.dcr-dataset.id
  }
}

resource "google_bigquery_analytics_hub_listing_iam_binding" "dcr-binding" {
  depends_on = [google_bigquery_analytics_hub_listing.dcr-listing]
  project = module.land-project.project_id
  location = var.location
  data_exchange_id = var.data_exchange
  listing_id = var.dcr_listing
  role = "roles/viewer"
  members = [
    "user:${var.super_admin}",
  ]
}

# This is a subscription from the landing zone to the Publisher's listing in the Clean Room
resource "null_resource" "subscribe-publisher-listing" {
  depends_on = [google_bigquery_analytics_hub_listing.publisher-listing]
  provisioner "local-exec" {
    command = <<-EOF
      curl --request POST \
      'https://analyticshub.googleapis.com/v1beta1/projects/${module.land-project.number}/locations/${var.location}/dataExchanges/${google_bigquery_analytics_hub_data_exchange.data-exchange.data_exchange_id}/listings/${google_bigquery_analytics_hub_listing.publisher-listing.listing_id}:subscribe' \
      --header "Authorization: Bearer $(gcloud auth print-access-token)" \
      --header 'Accept: application/json' \
      --header 'Content-Type: application/json' \
      --data '{ "destinationDataset": { "datasetReference": { "datasetId": "subscribed_publisher_dataset", "projectId": "${module.land-project.project_id}" }, "location": "${var.location}" } }' \
      --compressed
    EOF
  }
}