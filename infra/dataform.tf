resource "google_dataform_repository" "repo" {
  name     = "toolkit-martech-v8"
  region   = var.region

  git_remote_settings {
    url                                 = var.github_repo_url
    default_branch                      = "main"
    authentication_token_secret_version  = "projects/${var.project_id}/secrets/dataform-github-token/versions/latest"
  }

  workspace_compilation_overrides {
    default_database = var.project_id
    schema_suffix    = ""
    table_prefix     = ""
  }

  depends_on = [time_sleep.wait_for_iam]
}