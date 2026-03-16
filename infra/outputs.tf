output "project_id" {
  value       = var.project_id
  description = "ID do Projeto onde o toolkit foi instalado."
}

output "dataform_repository_id" {
  value       = google_dataform_repository.repo.name
  description = "Nome do repositório Dataform criado."
}

output "dataform_console_url" {
  value       = "https://console.cloud.google.com/bigquery/dataform/locations/${var.region}/repositories/${google_dataform_repository.repo.name}/details?project=${var.project_id}"
  description = "Link direto para o Dataform no Console do GCP."
}

output "workflow_id" {
  value       = google_workflows_workflow.v8_flow.id
  description = "ID do Workflow Orquestrador."
}

output "scheduler_job" {
  value       = google_cloud_scheduler_job.trigger.name
  description = "Nome do Job de agendamento diário."
}

output "toolkit_service_account" {
  value       = google_project_service_identity.dataform_sa.email
  description = "Service Account utilizada pelo Dataform para processar os dados."
}