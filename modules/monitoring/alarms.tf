# ==============================================================================
# Self-observability for the monitoring system
# ------------------------------------------------------------------------------
#
# A monitoring system that fails silently is worse than no monitoring: it shows
# green while everything is actually broken. The Pushgateway also retains the last
# pushed value forever, so a monitor that stops running looks "healthy". These
# alarms catch the failure modes that metrics alone cannot:
#   - the Lambda errors out (bad script, import error, timeout),
#   - the Lambda is throttled (concurrency/limits),
#   - the schedule never fires at all (EventBridge/permissions/NAT broken).
# Point `alarm_actions` at an SNS topic to get notified.
# ==============================================================================

# Fires when the Lambda throws (uncaught exception / non-zero exit). Tells
# you a monitor is broken even though the previously-pushed metrics still show.
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

# Fires when the Lambda is throttled, which would silently skip monitors
# under load. Useful early warning before errors start surfacing.
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

# Catches a completely dead schedule. If no invocation happens during the
# window (default 24h), something upstream is broken — EventBridge rule missing,
# role lost permission, or the subnet/NAT can't reach S3. `treat_missing_data =
# "breaching"` is critical here: absence of data must alarm, not stay quiet.
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
