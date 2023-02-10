locals {
  enabled = module.this.enabled
}

module "ci_user" {
  source  = "cloudposse/iam-system-user/aws"
  version = "1.1.0"
  count   = module.this.enabled ? 1 : 0
  context = module.this.context
}

module "cdn" {
  source                              = "cloudposse/cloudfront-s3-cdn/aws"
  version                             = "0.86.0"
  count                               = module.this.enabled ? 1 : 0
  context                             = module.this.context
  cloudfront_access_logging_enabled   = true
  cloudfront_access_log_create_bucket = true
  origin_path                         = "/anynews"
  deployment_principal_arns = {
    (module.ci_user[0].user_arn) = ["anynews/"]
  }
}
