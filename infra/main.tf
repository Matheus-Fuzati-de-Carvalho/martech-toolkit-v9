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
  provider = google-beta
  service  = "dataform.googleapis.com"
  depends_on = [google_project_service.apis]
}

# Permissões (Usando a SA de Compute como Orquestradora conforme v7)
data "google_project" "project" {}

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
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# CORREÇÃO AQUI: Os nomes nos depends_on devem ser os nomes definidos acima
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.df_permissions,
    google_project_iam_member.workflow_perms
  ]
  create_duration = "90s"
}

# Setup do Workspace (CURL para garantir que o workspace 'main' exista)
resource "null_resource" "workspace_init" {
  provisioner "local-exec" {
    command = <<EOT
      TOKEN=$(gcloud auth print-access-token)
      REPO_URL="https://dataform.googleapis.com/v1beta1/projects/${var.project_id}/locations/${var.region}/repositories/${google_dataform_repository.repo.name}"
      sleep 30
      curl -X POST -H "Authorization: Bearer $TOKEN" "$REPO_URL/workspaces?workspaceId=main" || true
      curl -X POST -H "Authorization: Bearer $TOKEN" "$REPO_URL/workspaces/main:pull"
EOT
  }
  # CORREÇÃO AQUI: O nome do sleep é wait_for_iam
  depends_on = [google_dataform_repository.repo, time_sleep.wait_for_iam]
}