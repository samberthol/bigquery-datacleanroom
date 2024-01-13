# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.


# Setting local variables for IAM
locals {
  prc_services = [
    "bigquerydatatransfer.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "iam.googleapis.com",
    "analyticshub.googleapis.com",  
    "storage.googleapis.com",
    "storage-component.googleapis.com",    
  ]
  iam_prc = {
    "roles/bigquery.admin" = [
      module.prc-sa-0.iam_email
    ]
    "roles/analyticshub.viewer" = [
      module.prc-sa-0.iam_email
    ]
    "roles/analyticshub.subscriber" = [
      module.prc-sa-0.iam_email
    ]
   "roles/analyticshub.publisher" = [
      module.prc-sa-0.iam_email
    ]
    "roles/storage.admin" = [
      module.prc-sa-0.iam_email
    ]
   "roles/iam.serviceAccountTokenCreator" = [
      module.prc-sa-0.iam_email
    ]   
  }
  publisher_schema_users = jsonencode([
    { name = "id", type = "INT64" },
    { name = "hashed_email", type = "STRING" },
    { name = "age", type = "INT64" },
    { name = "gender", type = "STRING" },
    { name = "city", type = "STRING" },
    { name = "country", type = "STRING" },
    { name = "traffic_source", type = "STRING" },
  ])  
}

# Defining the project for a publisher to the clean room
module "prc-project" {
  source          = "../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.processing
    : "${var.project_config.project_ids.processing}${local.project_suffix}"
  )
  iam = (
    var.project_config.billing_account_id != null ? {} : local.iam_prc
  )
  services = local.prc_services
}

module "prc-sa-0" {
  source       = "../modules/iam-service-account"
  project_id   = module.prc-project.project_id
  prefix       = var.prefix
  name         = "prc-sa-0"
  display_name = "Publisher zone service account."
}

resource "google_project_iam_member" "iam-prc" {
  for_each = { for role, members in local.iam_prc : role => members }
  role     = each.key
  member   = each.value[0]
  project  = module.prc-project.project_id
  depends_on = [module.prc-sa-0]
}

# Creating a Cloud Storage bucket to host the data from the publisher
module "prc-cs-0" {
  source         = "../modules/gcs"
  project_id     = module.prc-project.project_id
  prefix         = var.prefix
  name           = "prc-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  objects_to_upload = {
    sample-data = {
      name         = "users.csv"
      source       = "assets/users.csv"
      content_type = "text/csv"
    }
  }
}

# Creating a dataset to host the data from the publisher and transfer the data from the Cloud Storage 
module "publisher-dataset" {
  source         = "../modules/bigquery-dataset"
  project_id     = module.prc-project.project_id
  id             = "publisher_dataset"
  location       = var.location
  tables = {
    users = {
      friendly_name       = "users"
      schema = local.publisher_schema_users
    }
  }
}

resource "google_bigquery_data_transfer_config" "publisher-transfer" {
  depends_on = [module.prc-project, module.publisher-dataset]
  project = module.prc-project.project_id
  display_name           = "publisher-transfer"
  location               = var.location
  schedule               = "every 1 hours"
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = module.publisher-dataset.dataset_id
  service_account_name   = module.prc-sa-0.email
  params = {
    destination_table_name_template = "users"
    data_path_template               = "gs://${module.prc-cs-0.name}/users.csv"
    write_disposition       = "APPEND"
    file_format             = "CSV"
    field_delimiter         = ","
    skip_leading_rows       = 1
    encoding                = "UTF8"
  }
}

# Create a dataset and a view for the Data Clean Room
module "dcr-publisher-dataset" {
  source         = "../modules/bigquery-dataset"
  project_id     = module.prc-project.project_id
  id             = "dcr_publisher_dataset"
  location       = var.location
}

resource "null_resource" "dcr-publisher-view" {
  triggers = {
   always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "bq query --project_id ${module.prc-project.project_id} --nouse_legacy_sql 'CREATE OR REPLACE VIEW `${module.prc-project.project_id}.${module.dcr-publisher-dataset.dataset_id}.dcr_view` OPTIONS (privacy_policy= \"{\\\"aggregation_threshold_policy\\\": {\\\"threshold\\\" : 1, \\\"privacy_unit_columns\\\": \\\"hashed_email\\\"}}\") AS ( SELECT id, hashed_email, age, gender, city, country, traffic_source FROM `${module.prc-project.project_id}.${module.publisher-dataset.dataset_id}.users` )';"
  }
}

# Create a listing for the Data Clean Room
resource "google_bigquery_analytics_hub_listing" "publisher-listing" {
  project = module.land-project.project_id
  location         = var.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data-exchange.data_exchange_id
  listing_id       = "publisher_listing"
  display_name     = "publisher_listing"
  description      = "Publisher listing for the ${var.data_exchange} clean room"

  bigquery_dataset {
    dataset = module.dcr-publisher-dataset.id
  }
}

resource "google_bigquery_analytics_hub_listing_iam_binding" "publisher-binding" {
  project = module.prc-project.project_id
  location = var.location
  data_exchange_id = var.data_exchange
  listing_id = google_bigquery_analytics_hub_listing.publisher-listing.id
  role = "roles/viewer"
  members = [
    "user:${var.super_admin}",
  ]
}

