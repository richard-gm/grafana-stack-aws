## AWS ECS Service Connect Implementation

Implementing Service Connect involves defining a **private DNS namespace** (using `aws_service_discovery_private_dns_namespace`). Each ECS service (`aws_ecs_service`) then references this namespace and includes a `service_connect_configuration` block. This block specifies the service's **discovery name** and the **port clients will use**, which must correspond to a named `portMapping` in the task definition.

### The Problem: Service Connect Not Activating

Initially, even with correct Terraform configuration and state, the ECS service in AWS failed to fully activate Service Connect. Key symptoms included:

*   The **`ecs-service-connect-proxy` container was not injected** into running tasks.
*   Internal DNS resolution for Service Connect names (e.g., `service-name.namespace.dns`) **failed** from within containers.
*   The AWS ECS Console UI for the service showed Service Connect as "**Turned off**."

This indicated a disconnect where AWS wasn't fully applying the configuration despite Terraform's intent.

### The Solution: Forcing a New Deployment

The issue stemmed from ECS not fully picking up the Service Connect configuration changes. The resolution involved adding a `triggers` block to the `aws_ecs_service` resource in Terraform. By setting `triggers = { force_redeploy = timestamp() }`, every `terraform apply` forces a comprehensive `UpdateService` API call to AWS. This ensures all service properties, including the Service Connect configuration, are re-evaluated and correctly applied by ECS, initiating a new service deployment.

### Verification

After the forced deployment, successful verification included:

*   The **`ecs-service-connect-proxy` container was successfully observed** running alongside the main application container within tasks.
*   The AWS Console UI for the service correctly displayed **Service Connect as "Enabled."**
*   Crucially, **internal DNS resolution and HTTP connectivity** to the Service Connect endpoint (e.g., `prometheus:9091`) were successful from within other Service Connect-enabled containers in the same namespace.

### Key Takeaways for Developers

*   **Verify Actual State:** Always cross-reference your Terraform state with the live state in the AWS Console and using AWS CLI commands (`aws ecs describe-services`, `aws ecs describe-tasks`). Terraform's state reflects its last known configuration, but AWS services might not always fully apply complex changes without a complete re-evaluation.
*   **Force Deployments for Critical Changes:** For significant changes to ECS service configurations, especially those impacting runtime behavior like Service Connect, use the `triggers` block in Terraform or manually force a new deployment to ensure changes are fully picked up and applied by ECS.
*   **Leverage `aws ecs execute-command`:** This tool is invaluable for debugging network and DNS issues directly from within your running ECS containers.
*   **Security Groups:** Ensure your security groups allow necessary inbound and outbound traffic between Service Connect-enabled services on their respective ports.
*   **Check Proxy Logs:** If the Service Connect proxy container is present but resolution fails, its CloudWatch logs are the first place to look for specific errors.
