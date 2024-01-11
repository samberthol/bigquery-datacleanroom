# BigQuery Data Clean Room on Google Cloud deployment with Terraform
This project intends to provide a deployment of a Bigquery Data Clean Room on Google Cloud using Terraform.

Disclaimer : While writing this project, several features of the BigQuery Data Clean Room product are not yet available or still "Pre-GA" stage. Various workarounds have been used to make this Clean Room deployable. This is not supported code by Google and is provided on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND.

## Architecture Design

This is a simple diagram of a Data Clean Room on Google Cloud 
![diagram](./assets/cleanroom_arch.png)

## Components
This deployment is based on the Google Cloud [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) Terraform templates.

[BigQuery](https://cloud.google.com/bigquery/docs/introduction) is centric to the deployment of [Data Clean Rooms](https://cloud.google.com/bigquery/docs/data-clean-rooms) on Google Cloud. Yet Data can be imported from a BigQuery DataLake external bucket like S3 or GCS. 

In the current setup we use the DataExchange feature of BigQuery Analytics Hub since Data Clean Rooms are not yet fully available through the API. We implement on the DataExchange the [Privacy Policies](https://cloud.google.com/bigquery/docs/privacy-policies#what_is_a_privacy_policy) that enable to provide the same feature as the Data Clean Room does, by enforcing an `aggregation_threshold`.

In this architecture we deploy two projects, one for hosting the Data Clean Room and the second to simulate a subscriber project to the Clean Room. 

## Setup

### Prerequisites
You will need to have a working installation of [terraform](https://developer.hashicorp.com/terraform/install). The working version at the time writing this deployment is [Version 1.6.6](https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip). Upon initialization, the latest Terraform Google Cloud Provider will be downloaded (currently v5.11.0).

Since not all is implemented in the Google Cloud Terraform Provider or through the API, you will need to install the following tools to use this deployment :
- [gcloud](https://cloud.google.com/sdk/docs/install) official Google Cloud cli
- `bq` included with the gcloud installer
- `curl` for direct API calls

You will also need to have a power user with sufficient rights to create projects, administrate BigQuery and Analytics Hub.

### Dependencies
This deployment uses modules from the [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) provided by Google Cloud. Hence the easiest way to install is to put the content of this repo in a folder that is in the root of you cloud foundation fabric folder to access the modules.

### Set variables
All the variables that need to be set are instructed in the `terraform.tfvars` file.

### Running the deployment
Once you are in the folder of this repo you can issue the `terraform init` command such as :
```
user@penguin:~/bigquery-datacleanroom-main$ terraform init 
```
Then do a `terraform plan` to verify all dependencies and environment variables have been met :
```
user@penguin:~/bigquery-datacleanroom-main$ terraform plan 
```
You can then launch the actual deployment using the `terraform apply` command
```
user@penguin:~/bigquery-datacleanroom-main$ terraform terraform apply -auto-approve 
```

# Verify the Clean Room works
In order to verify it works you can go to the Google Cloud console and check that you have :
- Search for the newly created Projects that begin with the prefix you have set in the `terraform.tfvars` file
- You should see two newly created Datasets in BigQuery Studio for the `land-project` Project. The DCR shared dataset should have a view associated.
- In the `land-project` Project (hosting the Data Clean Room), you should have in the BigQuery > Analytics Hub, you should see an Exchange with a Listing associated. In the Exchange, you should see a Subscriber associated to the Listing.
- In the `curated-project` Project (for the Subscriber), you should see a Linked Dataset in BigQuery Studio

You can verify the Data Clean Room is effective by issuing a SQL query in the `curated-project` that takes advantage of the Aggregation features of the Clean Room, such as :
```
SELECT
WITH
  AGGREGATION_THRESHOLD OPTIONS(threshold=20, privacy_unit_column=id) 
  age,
  COUNT (DISTINCT id) AS countjointids
FROM
  `dcr1cur.subscribed_dataset.dcr_view` # Replace with your variables

GROUP BY
  age
ORDER BY
  1 desc;
```

## Troubleshooting & know issues
You will probably notice a failure upon initial deployment with setting IAM permissions for the public dataset to be copied to your project. This is because the IAM API from Google Cloud is async and "eventually consistent". The best way to fix this is to wait a couple minutes and launch the `terraform apply` command again. You can also view the logs of the [transfer page](https://console.cloud.google.com/bigquery/transfers) in the Run History tab.

When running `terraform destroy` you will notice that the datasets in BigQuery prevent you from cleaning the projects. You can delete the datasets from the cloud console and launch the `terraform destroy` command again.