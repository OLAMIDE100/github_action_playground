
variable "gcp_project_name" {
  type = string
  default = "dbt-sandbox-385616"
}


variable "region" {
  type = string
  default = "us-central1" 
}

variable "function_version" {
  type = string
  default = "1"
}

variable "solution"{
  default = "api_1_function_2"
}

