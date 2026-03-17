# ---------------------------------------------------------
# 1. REPOSITÓRIO DATAFORM
# ---------------------------------------------------------
resource "google_dataform_repository" "repo" {
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

  depends_on = [google_project_iam_member.df_permissions]
}

# ---------------------------------------------------------
# 2. INICIALIZAÇÃO DO WORKSPACE (Via API)
# ---------------------------------------------------------
resource "null_resource" "workspace_init" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Aguardando estabilização final..."
      sleep 60
      TOKEN=$(gcloud auth print-access-token)
      REPO_PATH="projects/${var.project_id}/locations/${var.region}/repositories/${google_dataform_repository.repo.name}"
      
      curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{}" "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces?workspaceId=main-workspace" || echo "⚠️ Workspace ja existe."
      curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{}" "https://dataform.googleapis.com/v1beta1/$REPO_PATH/workspaces/main-workspace:pull"
EOT
  }
  depends_on = [google_dataform_repository.repo, time_sleep.wait_for_iam]
}

# ---------------------------------------------------------
# 3. WORKFLOW (Orquestrador de Compilação e Execução)
# ---------------------------------------------------------
resource "google_workflows_workflow" "v8_flow" {
  name            = "martech-v8-orchestrator"
  region          = var.region
  service_account = google_service_account.martech_sa.id 
  
  source_contents = templatefile("${path.module}/workflow_definition.yaml", {
    project_id      = var.project_id,
    region          = var.region,
    repo_name       = google_dataform_repository.repo.name,
    flavor          = var.flavor,
    raw_ga4         = var.raw_ga4,
    raw_ads         = var.raw_ads,
    raw_ads_table   = var.raw_ads_table,
    silver_dataset  = var.silver_dataset,
    gold_dataset    = var.gold_dataset,
    tab_slv_ga4     = var.tab_slv_ga4,
    tab_slv_ads     = var.tab_slv_ads,
    tab_gld_mkt     = var.tab_gld_mkt,
    tab_gld_retail  = var.tab_gld_retail
  })

  depends_on = [time_sleep.wait_for_iam]
}

# ---------------------------------------------------------
# 4. CLOUD SCHEDULER (Agendamento do Workflow)
# ---------------------------------------------------------
resource "google_cloud_scheduler_job" "trigger" {
  name      = "daily-v8-sync"
  region    = var.region
  schedule  = var.schedule_cron
  time_zone = "America/Sao_Paulo"
  
  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.v8_flow.id}/executions"
    
    oauth_token {
      service_account_email = google_service_account.martech_sa.email
    }
  }

  depends_on = [google_workflows_workflow.v8_flow]
}