# infra/workflows.tf

# 1. Service Account para o Workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "martech-v9-workflow-sa"
  display_name = "Workflow Service Account - Martech Toolkit v9"
  project      = local.project_id
  depends_on = [time_sleep.wait_api_propagation]
}

# 2. Permissões para o Workflow controlar o Dataform
resource "google_project_iam_member" "workflow_dataform_editor" {
  project = local.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# 3. O recurso do Workflow
resource "google_workflows_workflow" "dataform_orchestrator" {
  name            = "martech-v9-orchestrator"
  region          = var.service_region
  service_account = google_service_account.workflow_sa.id
  project         = local.project_id

  # Carrega a lógica do ficheiro YAML
source_contents = templatefile("${path.module}/workflow_definition.yaml", {
    # 1. Parâmetros de Infraestrutura
    project_id         = local.project_id
    service_region     = var.service_region
    repository         = google_dataform_repository.martech_v9_repo.id
    notification_email = var.notification_email
    
    # 2. Configurações de Execução
    flavor             = var.flavor
    lookback_days      = var.lookback_days

    # 3. Fontes de Dados (RAW)
    raw_ga4_project    = local.project_id
    raw_ga4_dataset    = var.raw_ga4_dataset
    raw_ads_project    = local.project_id
    raw_ads_dataset    = var.raw_ads_dataset
    raw_ads_table      = var.raw_ads_table

    # 4. Camadas (Schemas)
    silver_schema      = var.silver_schema
    gold_schema        = var.refined_schema
    quality_schema     = "QUALITY"

    # 5. Nomes de Tabelas (Sincronizado com SQLX)
    tab_ft_ga4         = var.tab_ft_ga4
    tab_ft_ads         = var.tab_ft_ads
    tab_dm_mkt         = var.tab_dm_mkt
    tab_dm_retail      = var.tab_dm_retail
  })

  depends_on = [google_dataform_repository.martech_v9_repo]
}