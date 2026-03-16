provider "google" {
  project = var.project_id
  region  = var.region
}

# Habilitação de APIs Core
resource "google_project_service" "required_apis" {
  for_each = toset([
    "dataform.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com",
    "bigquery.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# Service Account do Executor do Toolkit
resource "google_service_account" "toolkit_sa" {
  account_id   = "martech-toolkit-v8-sa"
  display_name = "Martech Toolkit v8 Executor"
  depends_on   = [google_project_service.required_apis]
}

# Atribuição de Permissões (IAM)
resource "google_project_iam_member" "roles" {
  for_each = toset([
    "roles/bigquery.admin",
    "roles/dataform.editor",
    "roles/workflows.invoker",
    "roles/secretmanager.secretAccessor"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.toolkit_sa.email}"
}

# RESOLUÇÃO ERRO V7: Aguarda 60s para propagação do IAM antes de criar o repo Dataform
resource "time_sleep" "iam_propagation_wait" {
  depends_on      = [google_project_iam_member.roles]
  create_duration = "60s"
}

resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.toolkit_sa.email}"
}