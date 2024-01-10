# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Creating a Dataset to host the Data Clean Room
module "dcr-dataset" {
  source         = "../modules/bigquery-dataset"
  project_id     = module.land-project.project_id
  id             = var.dcr_dataset
  location       = var.location
}

# Creating a view with a privacy policy - this makes the dataexchange behave like a Data Clean Room 
resource "null_resource" "dcr_view" {
  triggers = {
   always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "bq query --project_id ${module.land-project.project_id} --nouse_legacy_sql 'CREATE OR REPLACE VIEW `${module.land-project.project_id}.dcr_dataset.dcr_view` OPTIONS (privacy_policy= \"{\\\"aggregation_threshold_policy\\\": {\\\"threshold\\\" : 20, \\\"privacy_unit_columns\\\": \\\"id\\\"}}\") AS ( SELECT id, age, email, state, city FROM `${module.land-project.project_id}.${module.thelook-dataset.dataset_id}.users` )';"
  }
}

# Creating a Data Exchange to host the Data Clean Room
# This is during the Data Clean Room is in Alpha as the API is not available/documented 
resource "google_bigquery_analytics_hub_data_exchange" "data_exchange" {
  project = module.land-project.project_id
  location         = var.location
  data_exchange_id = var.data_exchange
  display_name     = var.data_exchange
  description      = "Demo Data Clean Room ${var.data_exchange}"
}

resource "google_bigquery_analytics_hub_listing" "listing" {
  project = module.land-project.project_id
  location         = var.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  listing_id       = var.dcr_listing
  display_name     = var.dcr_listing
  description      = "Listing for the ${var.data_exchange} clean room"

  bigquery_dataset {
    dataset = module.dcr-dataset.id
  }
}

resource "google_bigquery_analytics_hub_listing_iam_binding" "binding" {
  project = module.land-project.project_id
  location = var.location
  data_exchange_id = var.data_exchange
  listing_id = var.dcr_listing
  role = "roles/viewer"
  members = [
    "user:${var.super_admin}",
  ]
}
