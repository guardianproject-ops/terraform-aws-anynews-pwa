output "ci_user_arn" {
  value       = local.enabled ? aws_iam_user.deploy_user.arn : null
  description = "The ARN of the IAM user for CI"
}
output "ci_user_access_key_id" {
  value       = local.enabled ? aws_iam_access_key.deploy_user_key_v1.id : null
  description = "The access key id for CI to publish the PWA into the bucket."
}

output "ci_user_secret_access_key" {
  value       = local.enabled ? aws_iam_access_key.deploy_user_key_v1.secret : null
  sensitive   = true
  description = "The secret access key for CI to publish the PWA into the bucket."
}

output "cdn" {
  value       = local.enabled ? module.cdn[0] : null
  description = "All the outputs from the upstream cloudposse/cloudfront-s3-cdn/aws module"
}

output "cf_domain_name" {
  value       = try(module.cdn[0].cf_domain_name, "")
  description = "Domain name corresponding to the distribution where the PWA is served."
}

output "s3_bucket_name" {
  value       = local.enabled ? module.cdn[0].s3_bucket : null
  description = "Name of S3 bucket where the PWA is hosted"
}