variable "project_id" {
  description = "GCP project ID"
}

variable "region" {
  description = "GCP region"
  default     = "us-central1"
}

variable "bucket_name" {
  description = "Name of the GCS bucket for raw data"
}

variable "credentials_file" {
  description = "Path to the GCP service account key file"
}