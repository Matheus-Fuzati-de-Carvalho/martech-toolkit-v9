# infra/outputs.tf

output "project_id" {
  value       = local.project_id
  description = "ID do projeto onde o Toolkit foi instalado"
}

output "dataform_repository_id" {
  value       = google_dataform_repository.martech_v9_repo.id
  description = "ID do repositório Dataform criado"
}

output "workflow_id" {
  value       = google_workflows_workflow.dataform_orchestrator.id
  description = "ID do orquestrador Cloud Workflows"
}

output "workflow_name" {
  value       = google_workflows_workflow.dataform_orchestrator.name
  description = "Nome do orquestrador para execução via gcloud"
}

output "workflow_sa_email" {
  value       = google_service_account.workflow_sa.email
  description = "E-mail da Service Account do Workflow para auditoria"
}

output "secret_id" {
  value       = google_secret_manager_secret.git_token_secret.id
  description = "ID do segredo que armazena o Git Token"
}

output "notification_topic" {
  value       = google_pubsub_topic.pipeline_alerts.id
  description = "Tópico de alertas para subscrições externas"
}

output "dashboard_url_hint" {
  value       = "https://console.cloud.google.com/dataplex/lakes/${google_dataplex_lake.martech_lake.name}?project=${local.project_id}"
  description = "Link direto para o Lake no Dataplex para visualização da linhagem"
}
