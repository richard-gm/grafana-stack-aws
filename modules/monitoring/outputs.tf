# Monitoring module outputs.

output "lambda_function_arn" {
  description = "ARN of the monitoring Lambda"
  value       = aws_lambda_function.monitoring.arn
}

output "lambda_function_name" {
  description = "Name of the monitoring Lambda"
  value       = aws_lambda_function.monitoring.function_name
}

output "lambda_layer_arn" {
  description = "ARN of the shared monitoring SDK layer"
  value       = aws_lambda_layer_version.sdk.arn
}

output "scripts_bucket_name" {
  description = "S3 bucket holding the monitoring scripts (uploaded by CI)"
  value       = aws_s3_bucket.scripts.id
}

output "scripts_bucket_arn" {
  description = "ARN of the scripts bucket"
  value       = aws_s3_bucket.scripts.arn
}
