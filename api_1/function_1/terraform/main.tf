terraform {
  required_providers {
    google = {
      version = "4.77.0"
    }
  }
}



terraform {
  backend "gcs" {
    bucket  = "irrcap_terraform_backend"
    prefix  = "gcp/api_1/function_1/state"
  }
}


provider "google" {
  
  project     = var.gcp_project_name
  region      = var.region 
}

resource "null_resource" "copy_helper_function" {
  provisioner "local-exec" {
    command = "cp -r ../../../loader ../../../junks ../cloudfunction/app"
  }
  triggers = {
            always_run = timestamp()
          }
}





data "archive_file" "source" {
    type        = "zip"
    source_dir  = "../cloudfunction/app"
    output_path = "api_1_function_1/${var.function_version}/function-source.zip"
     depends_on = [ null_resource.copy_helper_function]

}

resource "google_storage_bucket_object" "archive" {
          name   = "${data.archive_file.source.output_path}"
          bucket = "dbt-sandbox-cloudfunction-archive"
          source = "${data.archive_file.source.output_path}"

          depends_on = [ data.archive_file.source]
}





resource "google_cloudfunctions_function_iam_member" "member" {
  project         = google_cloudfunctions_function.eodhd_bulk_prices.project
  region          = google_cloudfunctions_function.eodhd_bulk_prices.region
  cloud_function  = google_cloudfunctions_function.eodhd_bulk_prices.name
  role            = "roles/cloudfunctions.invoker"
  member          = "serviceAccount:dbt-user@dbt-sandbox-385616.iam.gserviceaccount.com"
  depends_on      = [ google_cloudfunctions_function.eodhd_bulk_prices ]
}





resource "google_cloudfunctions_function" "eodhd_bulk_prices" {
  available_memory_mb          = 1024
  entry_point                  = "main"
  https_trigger_security_level = "SECURE_ALWAYS"

  ingress_settings             = "ALLOW_ALL"
 
  max_instances                 = 3000
  min_instances                 = 0
  name                          = var.solution
  project                       = var.gcp_project_name
  region                        = var.region
  runtime                       = "python39"
  service_account_email         = "dbt-sandbox-385616@appspot.gserviceaccount.com"
  source_archive_bucket         = "dbt-sandbox-cloudfunction-archive"
  source_archive_object         = google_storage_bucket_object.archive.name
  timeout                       = 300
  trigger_http                  = true
  environment_variables = {
   name = var.solution,
   age = var.function_version
  }
  
}

