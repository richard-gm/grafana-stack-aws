# ==============================================================================
# EventBridge schedule triggers
# ------------------------------------------------------------------------------
#
# The whole design hinges on a SINGLE Lambda doing many different monitoring jobs.
# Rather than deploying one Lambda per check (expensive, hard to scan at a glance),
# we keep one Lambda and fan out to it with multiple EventBridge *schedule* rules.
#
# Each entry in `var.monitoring_jobs` becomes:
#   1. an EventBridge rule on a cron/rate schedule,
#   2. a target pointing at the Lambda with a JSON payload {"script","job"},
#   3. a Lambda permission letting EventBridge invoke that function.
#
# Adding a new monitor is therefore a data change (one map entry), not a code
# change: no Lambda rebuild, no redeploy. The Lambda handler reads `script` from
# the event to decide which file to fetch from S3 and run.
#
# Note: `aws_cloudwatch_event_rule` (scheduled rules) has no native DLQ, so
# failure visibility relies on the CloudWatch alarms in alarms.tf.
# ==============================================================================

# Index the job list by name so the three `for_each` blocks below stay in sync
# and we can reference a job's fields by key (e.g. `local.jobs[each.key].script`).
locals {
  jobs = { for j in var.monitoring_jobs : j.name => j }
}

# (1) The schedule itself. One cron/rate rule per monitor. This is the "trigger"
#     that wakes the Lambda up; nothing runs unless a rule fires.
resource "aws_cloudwatch_event_rule" "job" {
  for_each = local.jobs

  name                = "${var.project_name}-${each.key}-${var.env_subfix}"
  description         = each.value.description
  schedule_expression = each.value.schedule

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-${each.key}-${var.env_subfix}"
  })
}

# (2) Wire the rule to the Lambda and tell the handler WHICH script to run.
#     The `input` is the only thing that differs between monitors; the Lambda,
#     the layer and the IAM role are all shared.
resource "aws_cloudwatch_event_target" "job" {
  for_each = local.jobs

  rule      = aws_cloudwatch_event_rule.job[each.key].name
  target_id = "${var.project_name}-${each.key}-${var.env_subfix}"
  arn       = aws_lambda_function.monitoring.arn
  input = jsonencode({
    script = each.value.script
    job    = each.value.job
  })
}

# (3) EventBridge is not allowed to invoke the Lambda until the function
#     explicitly grants it. This permission (scoped to this rule's ARN) is what
#     lets the schedule actually trigger the function.
resource "aws_lambda_permission" "allow_events" {
  for_each = local.jobs

  statement_id  = "AllowEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitoring.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.job[each.key].arn
}
