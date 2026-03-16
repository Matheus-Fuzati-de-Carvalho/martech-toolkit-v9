resource "google_dataform_repository" "repo" {
  provider = google-beta # <--- ADICIONE ISSO
  name     = "toolkit-martech-v8"
  region   = var.region

  git_remote_settings {
    url                                = var.github_repo_url
    default_branch                     = "main"
    authentication_token_secret_version = "projects/${var.project_id}/secrets/dataform-github-token/versions/latest"
  }

  workspace_compilation_overrides {
    default_database = var.project_id
  }

  # Garanta que o nome aqui bata com o main.tf
  depends_on = [time_sleep.wait_for_iam] 
}

# Nota: O Dataform não permite criar Workspaces persistentes via Terraform, 
# mas o Workflow abaixo executa o código direto da branch 'main', 
# eliminando a necessidade de um workspace para o funcionamento do pipeline.