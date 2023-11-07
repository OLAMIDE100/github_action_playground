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
    prefix  = "gcp/eodhd_bulk_prices/state"
  }
}


provider "google" {
  
  project     = var.gcp_project_name
  region      = var.region 
}


data "archive_file" "source" {
    type        = "zip"
    source_dir  = "../cloudfunction/app"
    output_path = "eodhd_bulk_prices/${var.function_version}/function-source.zip"
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
  environment_variables        = {}
  https_trigger_security_level = "SECURE_ALWAYS"

  ingress_settings             = "ALLOW_ALL"
 
  max_instances                 = 3000
  min_instances                 = 0
  name                          = "eodhd_bulk_prices_test"
  project                       = var.gcp_project_name
  region                        = var.region
  runtime                       = "python39"
  service_account_email         = "dbt-sandbox-385616@appspot.gserviceaccount.com"
  source_archive_bucket         = "dbt-sandbox-cloudfunction-archive"
  source_archive_object         = google_storage_bucket_object.archive.name
  timeout                       = 300
  trigger_http                  = true
  secret_environment_variables {
    key        = "EODHDAPIToken"
    project_id = "975294063990"
    secret     = "EODHDAPIToken"
    version    = "1"
  }
  
}


resource "google_cloud_scheduler_job" "bulk_prices_daily" {
  attempt_deadline = "180s"
  name             = "bulk_prices_daily_test"
  paused           = false
  project          = var.gcp_project_name
  region           = var.region
  schedule         = "0 4 * * 2-6"
  time_zone        = "America/New_York"
  http_target {
    body = "eyJFeGNoYW5nZXMiOlsiQVMiLCAiQlIiLCAiQ08iLCAiRiIsICJIRSIsICJJUiIsICJMUyIsICJMU0UiLCAiTUMiLCAiT0wiLCAiUEEiLCAiU1QiLCAiU1ciLCAiVVMiLCAiVkkiLCAiV0FSIiwgIlhFVFJBIl19"
    headers = {
      Content-Type = "application/json"
    }
    http_method = "POST"
    uri         = google_cloudfunctions_function.eodhd_bulk_prices.https_trigger_url
    oidc_token {
      audience              = google_cloudfunctions_function.eodhd_bulk_prices.https_trigger_url
      service_account_email = "dbt-user@dbt-sandbox-385616.iam.gserviceaccount.com"
    }
  }
  retry_config {
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
    retry_count          = 2
  }
  
}
