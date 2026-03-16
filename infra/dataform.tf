resource "google_dataform_repository" "v8_repo" {
  provider = google-beta
  name     = "martech_toolkit_v8"
  project  = var.project_id
  region   = var.region

  git_remote_settings {
    url                                = var.github_repo_url
    default_branch                     = "main"
    authentication_token_secret_version = "projects/${var.project_id}/secrets/${var.github_token_secret_name}/versions/latest"
  }

  service_account = google_service_account.toolkit_sa.email
  
  depends_on = [time_sleep.iam_propagation_wait]
}