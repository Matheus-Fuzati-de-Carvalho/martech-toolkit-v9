# infra/dataform.tf

# 1. Definição do Repositório Dataform
resource "google_dataform_repository" "martech_v9_repo" {
  provider = google-beta
  project  = local.project_id
  region   = var.region
  name     = "martech-toolkit-v9"

  git_remote_settings {
    url                                = "https://github.com/teu-usuario/martech-toolkit-v9.git" # URL FIXO
    default_branch                     = "main"
    authentication_token_secret_version = "projects/${local.project_id}/secrets/git-token/versions/latest"
  }

  workspace_compilation_overrides {
    default_database = local.project_id
  }

  depends_on = [google_project_service.services]
}

# 2. Identificação da Service Account padrão do Dataform
# O GCP cria automaticamente uma SA no formato: service-PROJECT_NUMBER@gcp-sa-dataform.iam.gserviceaccount.com
data "google_project" "project" {}

locals {
  dataform_sa = "service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# 3. Atribuição de Permissões (IAM) para a Service Account
# Essencial para que o Dataform consiga ler as fontes e escrever nos datasets criados
resource "google_project_iam_member" "dataform_bigquery_editor" {
  project = local.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${local.dataform_sa}"
}

resource "google_project_iam_member" "dataform_bigquery_job_user" {
  project = local.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${local.dataform_sa}"
}

# Permissão para o Dataform ler os metadados do INFORMATION_SCHEMA (necessário para o FinOps)
resource "google_project_iam_member" "dataform_metadata_viewer" {
  project = local.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:${local.dataform_sa}"
}
