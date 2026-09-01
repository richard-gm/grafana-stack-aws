# Alarms on the monitoring Lambda itself. A monitor that silently stops running
# still shows "healthy" (Pushgateway retains the last value), so these catch
# the failure modes metrics alone won't: errors, throttles, and a dead schedule.
# Send alerts via var.alarm_actions (e.g. SNS topic).

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

# treat_missing_data = "breaching" so a stalled schedule always fires.
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
