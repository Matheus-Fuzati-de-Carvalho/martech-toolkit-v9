resource "google_dataform_repository" "v8_repo" {
  name     = "beta-toolkit-martch"
  project  = var.project_id
  region   = "us-central1"

  git_remote_settings {
    url                                = var.github_repo_url
    default_branch                     = "main"
    authentication_token_secret_version = "projects/${var.project_id}/secrets/github-token-dataform/versions/latest"
  }

  service_account = google_service_account.toolkit_sa.email
  depends_on      = [time_sleep.wait_for_iam]
}

# Nota: O Dataform não permite criar Workspaces persistentes via Terraform, 
# mas o Workflow abaixo executa o código direto da branch 'main', 
# eliminando a necessidade de um workspace para o funcionamento do pipeline.