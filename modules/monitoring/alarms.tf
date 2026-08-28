# Alarms that make the monitoring system itself observable, so a dead Lambda or
# failing script does not fail silently (addresses the "last good value"
# false-green problem).

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-monitoring-errors-${var.env_subfix}"
  alarm_description   = "Monitoring Lambda emitted errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.monitoring.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-monitoring-throttles-${var.env_subfix}"
  alarm_description   = "Monitoring Lambda was throttled"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = aws_lambda_function.monitoring.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
}

# Catches a completely dead schedule: if no invocation happens in the window,
# something (EventBridge, permissions, subnet/NAT) is broken.
resource "aws_cloudwatch_metric_alarm" "lambda_no_invocations" {
  alarm_name          = "${var.project_name}-monitoring-no-invocations-${var.env_subfix}"
  alarm_description   = "Monitoring Lambda had no invocations in the evaluation window"
  namespace           = "AWS/Lambda"
  metric_name         = "Invocations"
  dimensions          = { FunctionName = aws_lambda_function.monitoring.function_name }
  statistic           = "Sum"
  period              = var.missed_run_period
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = var.alarm_actions
}
