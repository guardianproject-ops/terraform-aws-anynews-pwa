output "ci_user_access_key_id" {
  value       = local.enabled ? module.ci_user[0].access_key_id : null
  description = "The access key id for CI to publish the PWA into the bucket."
}

output "ci_user_secret_access_key" {
  value       = local.enabled ? module.ci_user[0].secret_access_key : null
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