# infra/secrets.tf

# 1. Cria a "caixa" do segredo no Secret Manager
resource "google_secret_manager_secret" "git_token_secret" {
  secret_id = "martech-v9-git-token"
  project   = local.project_id

  replication {
    auto {}
  }

  # Garante que a API do Secret Manager esteja ativa
  depends_on = [time_sleep.wait_api_propagation]
}

# 2. Cria a versão do segredo com o Token real
resource "google_secret_manager_secret_version" "git_token_version" {
  secret      = google_secret_manager_secret.git_token_secret.id
  secret_data = var.git_token
}

# 3. Permissão crucial: O Dataform precisa "ler" esse segredo
resource "google_secret_manager_secret_iam_member" "dataform_secret_accessor" {
  project   = local.project_id
  secret_id = google_secret_manager_secret.git_token_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.dataform_sa}"

  # AJUSTE FINO AQUI: 
  # Só tenta dar a permissão DEPOIS que o repositório for criado. 
  # Isso garante que a Service Account do Dataform já tenha sido "nascida" pelo GCP.
  depends_on = [google_dataform_repository.martech_v9_repo]
}