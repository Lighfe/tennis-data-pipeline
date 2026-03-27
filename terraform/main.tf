terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

resource "google_storage_bucket" "raw_data" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  # Uncomment to automatically delete files older than 30 days
  # lifecycle_rule {
  #   condition {
  #     age = 30
  #   }
  #   action {
  #     type = "Delete"
  #   }
  # }
}

resource "google_bigquery_dataset" "raw" {
  dataset_id                 = "tennis_raw"
  location                   = var.region
  delete_contents_on_destroy = true
}

resource "google_bigquery_dataset" "prod" {
  dataset_id                 = "tennis_prod"
  location                   = var.region
  delete_contents_on_destroy = true
}