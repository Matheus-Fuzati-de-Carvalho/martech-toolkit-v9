resource "google_workflows_workflow" "v8_flow" {
  name            = "martech-v8-orchestrator"
  region          = var.region
  service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  source_contents = templatefile("${path.module}/workflow.yaml", {
    project_id = var.project_id,
    region     = var.region,
    repo_name  = google_dataform_repository.repo.name,
    flavor     = var.flavor
  })
}

resource "google_cloud_scheduler_job" "v8_trigger" {
  name     = "daily-v8-sync"
  schedule = "0 6 * * *"
  region   = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.v8_flow.id}/executions"
    oauth_token {
      service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
    }
  }
}