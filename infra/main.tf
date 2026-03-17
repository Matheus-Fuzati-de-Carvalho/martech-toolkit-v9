# Ativação de APIs
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

# Identidade do Dataform
resource "google_project_service_identity" "dataform_sa" {
  provider   = google-beta
  service    = "dataform.googleapis.com"
  depends_on = [google_project_service.apis]
}

# Dados do Projeto
data "google_project" "project" {}

# Permissões do Dataform
resource "google_project_iam_member" "df_permissions" {
  for_each = toset(["roles/bigquery.admin", "roles/secretmanager.secretAccessor"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_project_service_identity.dataform_sa.email}"
}

# Criar Service Account dedicada para Workflow e Scheduler (Evita erro 400)
resource "google_service_account" "martech_sa" {
  account_id   = "martech-v8-orchestrator"
  display_name = "Service Account para Orquestrador Martech V8"
}

# Permissões para a NOVA Service Account
resource "google_project_iam_member" "workflow_perms" {
  for_each = toset(["roles/dataform.editor", "roles/workflows.invoker"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.martech_sa.email}"
}

# PAUSA TÉCNICA (Aguardando propagação de IAM)
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.df_permissions,
    google_project_iam_member.workflow_perms
  ]
  create_duration = "90s"
}

# Automação do Workspace
resource "null_resource" "workspace_init" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Aguardando estabilização total..."
      sleep 60
      TOKEN=$(gcloud auth print-access-token)
      REPO_PATH="projects/${var.project_id}/locations/${var.region}/repositories/toolkit-martech-v8"
      curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{}" "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces?workspaceId=main-workspace" || echo "⚠️ Workspace já existe."
      curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{}" "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces/main-workspace:pull"
EOT
  }
  depends_on = [time_sleep.wait_for_iam]
}

# Datasets Silver e Gold (Fixados em US)
resource "google_bigquery_dataset" "silver_ds" {
  dataset_id = var.silver_dataset
  location   = "US"
  depends_on = [google_project_service.apis]
}

resource "google_bigquery_dataset" "gold_ds" {
  dataset_id = var.gold_dataset
  location   = "US"
  depends_on = [google_project_service.apis]
}