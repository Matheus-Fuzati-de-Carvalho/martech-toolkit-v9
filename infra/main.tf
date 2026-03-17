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

# Automação do Workspace (Versão gcloud - Mais estável)
resource "null_resource" "workspace_init" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Aguardando 60s para o Dataform estabilizar a conexão com o Git..."
      sleep 60
      
      # Cria o workspace usando gcloud
      gcloud dataform workspaces create main-workspace \
        --repository=${google_dataform_repository.repo.name} \
        --location=${var.region} \
        --project=${var.project_id} || echo "⚠️ Workspace já pode existir."

      echo "📥 Sincronizando arquivos (Git Pull)..."
      gcloud dataform workspaces pull main-workspace \
        --repository=${google_dataform_repository.repo.name} \
        --location=${var.region} \
        --project=${var.project_id}
EOT
  }
  # Garante que as permissões e o repositório existam antes de tentar criar o workspace
  depends_on = [
    google_dataform_repository.repo, 
    time_sleep.wait_for_iam,
    google_project_iam_member.df_permissions
  ]
}

# Criação dos Datasets (Com depends_on para evitar erro de API)
resource "google_bigquery_dataset" "silver_ds" {
  dataset_id                  = var.silver_dataset
  location                    = var.region
  description                 = "Camada Silver do Toolkit Martech"
  delete_contents_on_destroy  = false
  depends_on                  = [google_project_service.apis]
}

resource "google_bigquery_dataset" "gold_ds" {
  dataset_id                  = var.gold_dataset
  location                    = var.region
  description                 = "Camada Gold do Toolkit Martech"
  delete_contents_on_destroy  = false
  depends_on                  = [google_project_service.apis]
}