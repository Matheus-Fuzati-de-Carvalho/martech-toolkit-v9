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

# Permissões do Workflow (usando SA padrão compute)
resource "google_project_iam_member" "workflow_perms" {
  for_each = toset(["roles/dataform.editor", "roles/workflows.invoker"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# PAUSA TÉCNICA (Ajustado para os nomes reais acima)
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.df_permissions,
    google_project_iam_member.workflow_perms
  ]
  create_duration = "90s"
}

# Automação completa do Workspace com Pull Inicial
resource "null_resource" "workspace_init" {
  provisioner "local-exec" {
    command = <<EOT
      TOKEN=$(gcloud auth print-access-token)
      REPO_PATH="projects/${var.project_id}/locations/${var.region}/repositories/${google_dataform_repository.repo.name}"
      
      echo "⏳ Aguardando 40s para estabilização do Git..."
      sleep 40

      echo "🛠️ Criando Workspace 'main-workspace'..."
      curl -X POST -H "Authorization: Bearer $TOKEN" \
           -H "Content-Type: application/json" \
           "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces?workspaceId=main-workspace" || echo "Workspace já existe."

      echo "📥 Sincronizando arquivos do GitHub (Pull)..."
      curl -X POST -H "Authorization: Bearer $TOKEN" \
           -H "Content-Type: application/json" \
           "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces/main-workspace:pull"
EOT
  }

  # GARANTA QUE O DEPENDS_ON ESTEJA ASSIM:
  depends_on = [
    google_dataform_repository.repo, 
    time_sleep.wait_for_iam
  ]
}