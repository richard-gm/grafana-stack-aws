locals {
  jobs = { for j in var.monitoring_jobs : j.name => j }
}

resource "aws_cloudwatch_event_rule" "job" {
  for_each = local.jobs

  name                = "${var.project_name}-${each.key}-${var.env_subfix}"
  description         = each.value.description
  schedule_expression = each.value.schedule

  tags = merge(var.tags_project, {
    Name = "${var.project_name}-${each.key}-${var.env_subfix}"
  })
}

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

resource "aws_lambda_permission" "allow_events" {
  for_each = local.jobs

  statement_id  = "AllowEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitoring.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.job[each.key].arn
}
