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
      subscriber_project_id           = module.cur-project.project_id,
      publisher_project_number        = module.prc-project.number,
      publisher_project_id            = module.prc-project.project_id      
    }
  }
}

output "service_accounts" {
  description = "Service account created."
  value = {
    Landing_DCR_SA    = module.land-sa-0.email,
    Subscriber_SA     = module.cur-sa-0.email,
    Publisher_SA      = module.prc-sa-0.email    
  }
}

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    thelook_dataset = module.thelook-dataset.dataset_id,
    datacleanroom_dataset = module.dcr-dataset.dataset_id,
    publisher_dataset = module.prc-dataset.dataset_id,
    publisher_dataset_dcr = module.dcr-publisher-dataset.dataset_id
  }
}

output "accounts" {
  description = "Accounts used and created"
  value = {
    data_exchange    = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id,
    listing          = google_bigquery_analytics_hub_listing.listing.listing_id,
    billing_account    = var.project_config.billing_account_id,
    super_admin       = var.super_admin,
    publisher_sa      = module.prc-sa-0.email,
    subscriber_sa     = module.cur-sa-0.email,
    landing_sa        = module.land-sa-0.email   
  }
}
