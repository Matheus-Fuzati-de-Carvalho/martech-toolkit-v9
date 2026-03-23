main:
  params: [args]
  steps:
    - init:
        assign:
          - project_id: "${project_id}"
          - repository: "${repository}"
          - flavor: "${flavor}"

    - compile_dataform:
        call: http.post
        args:
          # Corrigido: Usamos apenas a variável direta para evitar o erro de sintaxe do Terraform
          url: $${"https://dataform.googleapis.com/v1beta1/" + repository + "/compilationResults"}
          auth: {type: OAuth2}
          body:
            # gitCommitish: "main"
            workspace: $${repository + "/workspaces/${workspace_name}"}
            codeCompilationConfig:
              vars:
                project_id: "${project_id}"
                raw_ga4_project: "${raw_ga4_project}"
                raw_ga4_dataset: "${raw_ga4_dataset}"
                raw_ads_project: "${raw_ads_project}"
                raw_ads_dataset: "${raw_ads_dataset}"
                raw_ads_table: "${raw_ads_table}"
                silver_schema: "${silver_schema}"
                gold_schema: "${gold_schema}"
                quality_schema: "${quality_schema}"
                tab_ft_ga4: "${tab_ft_ga4}"
                tab_ft_ads: "${tab_ft_ads}"
                tab_dm_mkt: "${tab_dm_mkt}"
                tab_dm_retail: "${tab_dm_retail}"
                flavor: "${flavor}"
                lookback_days: "${lookback_days}"
        result: compilation_result

    - run_invocation:
        try:
          steps:
            - create_invocation:
                call: http.post
                args:
                  # Corrigido para matar o 404
                  url: $${"https://dataform.googleapis.com/v1beta1/" + repository + "/workflowInvocations"}
                  auth: {type: OAuth2}
                  body:
                    compilationResult: $${compilation_result.body.name}
                    invocationConfig:
                      includedTags: ["${flavor}"]
                      transitiveDependenciesIncluded: true
                result: invocation

            - wait_for_completion:
                call: http.get
                args:
                  url: $${"https://dataform.googleapis.com/v1beta1/" + invocation.body.name}
                  auth: {type: OAuth2}
                result: invocation_status

            - check_status:
                switch:
                  - condition: $${invocation_status.body.state == "RUNNING"}
                    next: wait_for_completion
                  - condition: $${invocation_status.body.state != "SUCCEEDED"}
                    raise: "Workflow invocation failed"
        
        retry:
          attempts: 2
          backoff:
            initial_delay: 30
            multiplier: 1

        except:
          as: e
          steps:
            - prepare_error_payload:
                assign:
                  - error_map:
                      message: $${e.message}
                      flavor: "${flavor}"
                      project: "${project_id}"
                  - error_json_str: $${json.encode_to_string(error_map)}
            - publish_to_pubsub:
                call: googleapis.pubsub.v1.projects.topics.publish
                args:
                  topic: "projects/${project_id}/topics/martech-v9-alerts"
                  body:
                    messages:
                      - data: $${base64.encode(text.encode(error_json_str))}