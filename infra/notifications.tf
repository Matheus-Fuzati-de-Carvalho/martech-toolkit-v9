# infra/notifications.tf

# 1. Tópico Pub/Sub para Alertas
resource "google_pubsub_topic" "pipeline_alerts" {
  name    = "martech-v9-alerts"
  project = local.project_id
}

# 2. Permissão: Permite que a Service Account do Workflow publique no tópico
resource "google_pubsub_topic_iam_member" "workflow_publisher" {
  project = local.project_id
  topic   = google_pubsub_topic.pipeline_alerts.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# 3. Cloud Function (Gen2) que enviará o e-mail
# Para o protótipo, vamos usar uma função simples em Python
resource "google_cloudfunctions2_function" "email_notifier" {
  name        = "martech-v9-email-sender"
  location    = var.region
  project     = local.project_id
  description = "Envia notificações de erro do Dataform por e-mail"

  build_config {
    runtime     = "python311"
    entry_point = "send_email_notification" 
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256Mi"
    timeout_seconds    = 60
    # Passa o e-mail configurado no variables.tf para a função
    environment_variables = {
      NOTIFICATION_EMAIL = var.notification_email
      # Se for usar SendGrid, injetamos a chave aqui futuramente
      # SENDGRID_API_KEY = var.sendgrid_api_key 
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.pipeline_alerts.id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [google_project_service.services]
}

# 4. Bucket para guardar o código da função (exigência do GCP)
resource "google_storage_bucket" "function_bucket" {
  name                        = "${local.project_id}-fn-sources"
  location                    = var.region
  project                     = local.project_id
  uniform_bucket_level_access = true
  force_destroy               = true # Para deletar fácil se o protótipo acabar
}

# 5. Zipando os arquivos físicos da pasta files/
data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/function_deploy.zip" # Output fora da pasta files para evitar recursão
  
  source {
    content  = file("${path.module}/files/main.py")
    filename = "main.py"
  }
  
  source {
    content  = file("${path.module}/files/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}