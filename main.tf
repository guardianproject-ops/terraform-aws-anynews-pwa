locals {
  enabled = module.this.enabled
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}


resource "aws_iam_user" "deploy_user" {
  name = module.this.id
  tags = module.this.tags
}

resource "aws_iam_access_key" "deploy_user_key_v1" {
  user   = aws_iam_user.deploy_user.name
  status = "Active"
}

data "aws_iam_policy_document" "deploy_rw" {
  statement {
    sid = "AllowBucketList"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.cdn[0].s3_bucket_arn
    ]
  }
  statement {
    sid = "AllowBucketRW"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${module.cdn[0].s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "deploy_rw" {
  name   = "AllowIamUserBucketRW-${module.this.id}"
  user   = aws_iam_user.deploy_user.name
  policy = data.aws_iam_policy_document.deploy_rw.json
}


module "lambda_edge" {
  source  = "cloudposse/cloudfront-s3-cdn/aws//modules/lambda@edge"
  version = "0.86.0"
  count   = local.enabled ? 1 : 0
  functions = {

    cors = {
      source = [{
        content  = <<-EOT
        exports.handler = (event, context, callback) => {
          const response = event.Records[0].cf.response;
          const request = event.Records[0].cf.request;
          response.headers["access-control-allow-origin"] = [{ key: "access-control-allow-origin", value: "*" }];

          if (!response.headers['vary']) {
              // source: https://serverfault.com/questions/856904/chrome-s3-cloudfront-no-access-control-allow-origin-header-on-initial-xhr-req
              response.headers['vary'] = [
                { key: 'Vary', value: 'Access-Control-Request-Headers' },
                { key: 'Vary', value: 'Access-Control-Request-Method' },
                { key: 'Vary', value: 'Origin' },
              ];
          }

          callback(null, response);
        };
        EOT
        filename = "index.js"
      }]
      runtime      = "nodejs18.x"
      handler      = "index.handler"
      event_type   = "origin-response"
      include_body = false
    }

    folder_index = {
      source = [{
        content  = <<-EOT
        exports.handler = (event, context, callback) => {
          /*
          * Expand S3 request to have index.html if it ends in /
          */
          const request = event.Records[0].cf.request;
          if ((request.uri !== "/") /* Not the root object, which redirects properly */
              && (request.uri.endsWith("/") /* Folder with slash */
                  || (request.uri.lastIndexOf(".") < request.uri.lastIndexOf("/")) /* Most likely a folder, it has no extension (heuristic) */
                  )) {
              if (request.uri.endsWith("/"))
                  request.uri = request.uri.concat("index.html");
              else
                  request.uri = request.uri.concat("/index.html");
          }
          callback(null, request);
        };
        EOT
        filename = "index.js"
      }]
      runtime      = "nodejs18.x"
      handler      = "index.handler"
      event_type   = "origin-request"
      include_body = false
    }
  }

  providers = {
    aws = aws.us-east-1
  }

  attributes = ["lambda"]
  context    = module.this.context
}

module "cdn" {
  #source                              = "cloudposse/cloudfront-s3-cdn/aws"
  #version                             = "0.86.0"
  source                              = "git::https://github.com/abeluck/terraform-aws-cloudfront-s3-cdn.git?ref=fix/bug-257"
  count                               = local.enabled ? 1 : 0
  context                             = module.this.context
  cloudfront_access_logging_enabled   = true
  cloudfront_access_log_create_bucket = true
  deployment_principals = {
    "deploy_user" : {
      "arn" : aws_iam_user.deploy_user.arn
      "path_prefix" : [""]
    }
  }
  lambda_function_association = module.lambda_edge[0].lambda_function_association
}