# infra/scheduler.tf

# 1. Cria o Job no Cloud Scheduler
resource "google_cloud_scheduler_job" "workflow_trigger" {
  name             = "martech-v9-daily-schedule"
  description      = "Trigger fixo para o orquestrador Dataform v9"
  schedule         = var.cron_schedule
  time_zone        = "America/Sao_Paulo"
  attempt_deadline = "320s"
  project          = local.project_id
  region           = var.service_region

  # O Scheduler chama a API de execução do Workflow
  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${local.project_id}/locations/${var.service_region}/workflows/${google_workflows_workflow.dataform_orchestrator.name}/executions"
    
    oauth_token {
      service_account_email = google_service_account.workflow_sa.email
    }
    
    # Corpo vazio, pois os parâmetros já estão "hardcoded" no template do Workflow
    body = base64encode("{}")
  }

  depends_on = [time_sleep.wait_api_propagation]
}