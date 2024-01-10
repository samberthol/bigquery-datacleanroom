# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

output "projects" {
  description = "GCP Projects information."
  value = {
    projects = {
      datacleanroom_project_number    = module.land-project.number,
      datacleanroom_roject_id         = module.land-project.project_id,
      subscriber_project_number       = module.cur-project.number,
      subscriber_project_id           = module.cur-project.project_id
    }
  }
}

output "service_accounts" {
  description = "Service account created."
  value = {
    landing    = module.land-sa-0.email,
    curated    = module.cur-sa-0.email
  }
}

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    thelook_dataset       = module.thelook-dataset.dataset_id,
    datacleanroom_dataset = module.dcr-dataset.dataset_id
  }
}

output "data_exchange" {
  description = "Service account created."
  value = {
    data_exchange    = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id,
    listing          = google_bigquery_analytics_hub_listing.listing.listing_id
  }
}