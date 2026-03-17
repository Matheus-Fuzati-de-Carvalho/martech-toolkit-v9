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

# Permissões do Workflow (SA padrão compute)
resource "google_project_iam_member" "workflow_perms" {
  for_each = toset(["roles/dataform.editor", "roles/workflows.invoker"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# PAUSA TÉCNICA (Aguardando propagação de IAM)
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.df_permissions,
    google_project_iam_member.workflow_perms
  ]
  create_duration = "90s"
}

# Automação do Workspace (Versão API REST - À prova de falhas do gcloud)
resource "null_resource" "workspace_init" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Aguardando 60s para estabilização total (IAM + Git)..."
      sleep 60
      
      TOKEN=$(gcloud auth print-access-token)
      REPO_PATH="projects/${var.project_id}/locations/${var.region}/repositories/${google_dataform_repository.repo.name}"
      
      echo "🛠️ Criando Workspace 'main-workspace' via API..."
      curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{}" \
        "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces?workspaceId=main-workspace" || echo "⚠️ Workspace já existe."

      echo "📥 Sincronizando arquivos (Git Pull) via API..."
      curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{}" \
        "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces/main-workspace:pull"
EOT
  }
  depends_on = [
    google_dataform_repository.repo, 
    time_sleep.wait_for_iam
  ]
}

# Criação do Dataset Silver (Fixado em US)
resource "google_bigquery_dataset" "silver_ds" {
  dataset_id                  = var.silver_dataset
  location                    = "US" # <--- FORÇAMOS 'US' AQUI PARA OS DADOS
  description                 = "Camada Silver do Toolkit Martech"
  delete_contents_on_destroy  = false
  depends_on                  = [google_project_service.apis]
}

# Criação do Dataset Gold (Fixado em US)
resource "google_bigquery_dataset" "gold_ds" {
  dataset_id                  = var.gold_dataset
  location                    = "US" # <--- FORÇAMOS 'US' AQUI PARA OS DADOS
  description                 = "Camada Gold do Toolkit Martech"
  delete_contents_on_destroy  = false
  depends_on                  = [google_project_service.apis]
}