# infra/secrets.tf

# 1. Cria a "caixa" do segredo no Secret Manager
resource "google_secret_manager_secret" "git_token_secret" {
  project   = local.project_id
  secret_id = "martech-v9-git-token"

  replication {
    auto {}
  }

  depends_on = [google_project_service.services]
}

# 2. Insere o valor do Token que virá do deploy.sh
resource "google_secret_manager_secret_version" "git_token_version" {
  secret      = google_secret_manager_secret.git_token_secret.id
  secret_data = var.git_token
}

# 3. Permissão crucial: O Dataform precisa "ler" esse segredo para se conectar ao Git
resource "google_secret_manager_secret_iam_member" "dataform_secret_accessor" {
  project   = local.project_id
  secret_id = google_secret_manager_secret.git_token_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.dataform_sa}"
}