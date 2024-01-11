# Samuel Berthollier - 2024
#
# Unless required by applicable law or agreed to in writing, software
# distributed is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

variable "super_admin" {
  description = "Listing of a dataset in the Data Clean Room"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters, CloudSQL instances) in this blueprint. When this field is set in Terraform state, a terraform destroy or terraform apply that would delete data storage resources will fail."
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_services" {
  description = "Flag to enable or disable services in the Data Platform."
  type = object({
    composer                = optional(bool, true)
    dataproc_history_server = optional(bool, true)
  })
  default = {}
}

variable "groups" {
  description = "User groups."
  type        = map(string)
  default = {
    data-analysts  = "gcp-data-analysts"
    data-engineers = "gcp-data-engineers"
    data-security  = "gcp-data-security"
  }
}

variable "location" {
  description = "Location used for multi-regional resources."
  type        = string
  default     = "eu"
}

variable "organization_domain" {
  description = "Organization domain."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_config" {
  description = "Provide 'billing_account_id' value if project creation is needed, uses existing 'project_ids' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = optional(string, null)
    parent             = string
    project_ids = optional(object({
      landing    = string
      processing = string
      curated    = string
      common     = string
      }), {
      landing    = "lnd"
      processing = "prc"
      curated    = "cur"
      common     = "cmn"
      }
    )
  })
  validation {
    condition     = var.project_config.billing_account_id != null || var.project_config.project_ids != null
    error_message = "At least one of project_config.billing_account_id or var.project_config.project_ids should be set."
  }
}

variable "project_suffix" {
  description = "Suffix used only for project ids."
  type        = string
  default     = null
}

variable "region" {
  description = "Region used for regional resources."
  type        = string
  default     = null
}

variable "service_encryption_keys" {
  description = "Cloud KMS to use to encrypt different services. Key location should match service region."
  type = object({
    bq       = optional(string)
    composer = optional(string)
    compute  = optional(string)
    storage  = optional(string)
  })
  nullable = false
  default  = {}
}

variable "thelook_dataset" {
  description = "Dataset copied from thelook_ecommerce"
  type        = string
  default     = null
}

variable "dcr_dataset" {
  description = "Dataset hosting the Data Clean Room"
  type        = string
  default     = null
}

variable "data_exchange" {
  description = "Demo Data Clean Room"
  type        = string
  default     = null
}

variable "dcr_listing" {
  description = "Listing of a dataset in the Data Clean Room"
  type        = string
  default     = null
}
