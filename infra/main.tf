# ---------------------------------------------------------
# 1. ATIVAÇÃO DE APIS
# ---------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com", 
    "bigquery.googleapis.com",
    "dataform.googleapis.com", 
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com", 
    "secretmanager.googleapis.com",
    "iam.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# ---------------------------------------------------------
# 2. IDENTIDADES DE SERVIÇO (Evita erros 400 de Agente Não Encontrado)
# ---------------------------------------------------------
resource "google_project_service_identity" "dataform_sa" {
  provider   = google-beta
  service    = "dataform.googleapis.com"
  depends_on = [google_project_service.apis]
}

resource "google_project_service_identity" "workflows_agent" {
  provider   = google-beta
  service    = "workflows.googleapis.com"
  depends_on = [google_project_service.apis]
}

# ---------------------------------------------------------
# 3. CRIAÇÃO DA SERVICE ACCOUNT DEDICADA (Orquestrador)
# ---------------------------------------------------------
resource "google_service_account" "martech_sa" {
  account_id   = "martech-v8-orchestrator"
  display_name = "Service Account para Orquestrador Martech V8"
  depends_on   = [google_project_service.apis]
}

# ---------------------------------------------------------
# 4. PERMISSÕES (IAM)
# ---------------------------------------------------------

# Permissões para o Dataform ler Secrets e gravar no BigQuery
resource "google_project_iam_member" "df_permissions" {
  for_each = toset(["roles/bigquery.admin", "roles/secretmanager.secretAccessor"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_project_service_identity.dataform_sa.email}"
}

# Permissões para a Service Account do Orquestrador rodar Workflow e Dataform
resource "google_project_iam_member" "workflow_perms" {
  for_each = toset(["roles/dataform.editor", "roles/workflows.invoker"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.martech_sa.email}"
}

# ---------------------------------------------------------
# 5. PAUSA TÉCNICA (Essencial para propagação do IAM)
# ---------------------------------------------------------
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.df_permissions,
    google_project_iam_member.workflow_perms,
    google_project_service_identity.workflows_agent
  ]
  create_duration = "90s"
}

# ---------------------------------------------------------
# 6. RECURSOS DE DADOS (BigQuery)
# ---------------------------------------------------------
resource "google_bigquery_dataset" "silver_ds" {
  dataset_id                 = var.silver_dataset
  location                   = "US" # Mantendo padrão GA4
  description                = "Camada Silver do Toolkit Martech"
  delete_contents_on_destroy = false
  depends_on                 = [google_project_service.apis]
}

resource "google_bigquery_dataset" "gold_ds" {
  dataset_id                 = var.gold_dataset
  location                   = "US"
  description                = "Camada Gold do Toolkit Martech"
  delete_contents_on_destroy = false
  depends_on                 = [google_project_service.apis]
}