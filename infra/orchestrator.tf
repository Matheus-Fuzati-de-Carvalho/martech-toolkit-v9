resource "google_workflows_workflow" "dataform_orchestrator" {
  name            = "dataform-martech-v8-flow"
  region          = var.region
  description     = "Orquestrador do Dataform v8 via API"
  service_account = google_service_account.toolkit_sa.id

  source_contents = <<EOF
main:
  params: [args]
  steps:
    - init:
        assign:
          - repository: "projects/$${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}/locations/${var.region}/repositories/martech_toolkit_v8"
    - createCompilationResult:
        call: http.post
        args:
          url: $${"https://dataform.googleapis.com/v1beta1/" + repository + "/compilationResults"}
          auth:
            type: OAuth2
          body:
            gitCommitish: "main"
        result: compilationResult
    - createWorkflowInvocation:
        call: http.post
        args:
          url: $${"https://dataform.googleapis.com/v1beta1/" + repository + "/workflowInvocations"}
          auth:
            type: OAuth2
          body:
            compilationResult: $${compilationResult.body.name}
            invocationConfig:
              includedTags: ["${var.flavor}"]
              transitiveDependenciesIncluded: true
        result: invocation
    - returnResult:
        return: $${invocation.body.name}
EOF
}