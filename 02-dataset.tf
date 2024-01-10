# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.


# Defining the IAM for the 

module "thelook-dataset" {
  source         = "../modules/bigquery-dataset"
  project_id     = module.land-project.project_id
  id             = var.thelook_dataset
  location       = var.location
}

resource "google_bigquery_data_transfer_config" "thelooktransfer" {
  depends_on = [module.land-project, module.land-sa-0, module.thelook-dataset]
  project = module.land-project.project_id
  display_name           = "thelooktransfer"
  location               = var.location
  data_source_id         = "cross_region_copy"
  destination_dataset_id = module.thelook-dataset.dataset_id
  service_account_name   = module.land-sa-0.email
  params = {
    source_dataset_id       = "thelook_ecommerce"
    source_project_id       = "bigquery-public-data"
  }
}

resource "null_resource" "set_transfer_iam" {
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [google_bigquery_data_transfer_config.thelooktransfer]
  provisioner "local-exec" {
    command = "gcloud iam service-accounts add-iam-policy-binding ${module.land-sa-0.email} --member='serviceAccount:service-${module.land-project.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com' --role='roles/iam.serviceAccountTokenCreator'"
  }
}

resource "null_resource" "run_transfer" {
  depends_on = [google_bigquery_data_transfer_config.thelooktransfer]
  provisioner "local-exec" {
    command = "bq mk --transfer_run --run_time='2022-08-19T12:11:35.00Z' ${google_bigquery_data_transfer_config.thelooktransfer.name}"
  }
}
