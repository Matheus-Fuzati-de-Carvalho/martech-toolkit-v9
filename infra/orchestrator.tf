resource "google_workflows_workflow" "v8_flow" {
  name            = "martech-v8-orchestrator"
  region          = var.region
  service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  
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

  depends_on = [google_dataform_repository.repo]
}

# Job do Scheduler (mantenha como está)
resource "google_cloud_scheduler_job" "trigger" {
  name     = "daily-v8-sync"
  region   = var.region
  schedule = "0 6 * * *"
  
  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.v8_flow.id}/executions"
    oauth_token {
      service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
    }
  }
}