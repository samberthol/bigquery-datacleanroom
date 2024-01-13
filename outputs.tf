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

output "accounts" {
  description = "Service account created."
  value = {
    Landing_DCR_SA    = module.land-sa-0.email,
    Subscriber_SA     = module.cur-sa-0.email,
    Publisher_SA      = module.prc-sa-0.email   
    Billing_account   = var.project_config.billing_account_id,
    Super_admin       = var.super_admin    
  }
}

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    thelook_dataset        = module.thelook-dataset.dataset_id,
    datacleanroom_dataset  = module.dcr-dataset.dataset_id,
    publisher_dataset      = module.publisher-dataset.dataset_id,
    publisher_dataset_dcr  = module.dcr-publisher-dataset.dataset_id
  }
}

output "data_exchange" {
  description = "Accounts used and created"
  value = {
    data_exchange               = google_bigquery_analytics_hub_data_exchange.data-exchange.data_exchange_id,
    dcr_listing                 = google_bigquery_analytics_hub_listing.dcr-listing.listing_id,
    Publisher_listing           = google_bigquery_analytics_hub_listing.publisher-listing.listing_id 
  }
}
