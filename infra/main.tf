terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.44.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.44.0"
    }
  }
}

# 1. APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com", "bigquery.googleapis.com",
    "dataform.googleapis.com", "workflows.googleapis.com",
    "cloudscheduler.googleapis.com", "secretmanager.googleapis.com",
    "iam.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# 2. Identidades (Service Agents)
resource "google_project_service_identity" "dataform_sa" {
  provider = google-beta
  service  = "dataform.googleapis.com"
  depends_on = [google_project_service.apis]
}

resource "google_project_service_identity" "workflows_agent" {
  provider = google-beta
  service  = "workflows.googleapis.com"
  depends_on = [google_project_service.apis]
}

# 3. Service Account do Orquestrador
resource "google_service_account" "martech_sa" {
  account_id   = "martech-v8-orchestrator"
  display_name = "Service Account para Orquestrador Martech V8"
}

# 4. IAM
resource "google_project_iam_member" "df_permissions" {
  for_each = toset(["roles/bigquery.admin", "roles/secretmanager.secretAccessor"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_project_service_identity.dataform_sa.email}"
}

resource "google_project_iam_member" "workflow_perms" {
  for_each = toset(["roles/dataform.editor", "roles/workflows.invoker"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.martech_sa.email}"
}

# 5. Pausa para Propagação
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.df_permissions,
    google_project_iam_member.workflow_perms,
    google_project_service_identity.workflows_agent
  ]
  create_duration = "90s"
}

# 6. Datasets
resource "google_bigquery_dataset" "silver_ds" {
  dataset_id = var.silver_dataset
  location   = "US"
  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "gold_ds" {
  dataset_id = var.gold_dataset
  location   = "US"
  delete_contents_on_destroy = false
}