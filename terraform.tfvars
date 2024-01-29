# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Define the prefix of the ressource names
prefix              	= "dcr1" 

# Define a power user that can deploy projects and is bigquery admin 
super_admin = "" # email format

# Define the project configuration
project_config = {
    parent              = "" # Your folder ID in the format "folders/PROJECT_NUMBER"
    billing_account_id  = "" # Your billing account ID in the format XXXXXX-XXXXXX-XXXXXX
}

organization_domain 	= "" # Your organization domain like "example.com"

# Target Dataset name for the BigQuery Datatransfer from the thelook_ecommerce public dataset
thelook_dataset = "thelook" # should onlycontain lowercase letters, numbers and underscores

# Define the Clean Room configuration
data_exchange = "DataCleanRoom"
dcr_dataset = "dcr_dataset"
dcr_listing = "dcr_listing"

# Location
location = "eu"

# If set to true, allow Terraform to delete all the tables in the publisher_dataset when destroying the resource
delete_contents_on_destroy = true

# Configures deletion_protection for the users table. If unset, module-level deletion_protection setting will be used.
deletion_protection = false
