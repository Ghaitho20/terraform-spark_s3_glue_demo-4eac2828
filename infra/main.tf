
# ─────────────────────────────────────────────────────────────────────────────
# Remote backend — state stored in S3, locking via DynamoDB
# (Provisioned by the bootstrap/ folder)
# ─────────────────────────────────────────────────────────────────────────────
terraform {
  backend "s3" {
    bucket         = "tfstate-spark-s3-glue-demo-ec5j706i"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tflock-spark-s3-glue-demo-ec5j706i"
    encrypt        = true
  }
}zg
hellohihi hi jzkgzrgzrgzrg

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 18
  special = false
  upper   = false
}

resource "aws_s3_bucket" "glue_scripts" {
  bucket        = "${var.glue_scripts_bucket_base_name}-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "glue_scripts" {
  bucket                  = aws_s3_bucket.glue_scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "pipeline_output" {
  bucket        = "${var.pipeline_output_bucket_base_name}-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "pipeline_output" {
  bucket = aws_s3_bucket.pipeline_output.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_output" {
  bucket = aws_s3_bucket.pipeline_output.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_output" {
  bucket                  = aws_s3_bucket.pipeline_output.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "local_file" "glue_test_script" {
  filename = "${path.module}/glue_test_script.py"
  content  = <<EOF
print("Hello from TEST script")
EOF
}

data "archive_file" "glue_test_script_zip" {
  type        = "zip"
  source_file = local_file.glue_test_script.filename
  output_path = "${path.module}/glue_test_script.zip"
}

resource "aws_s3_object" "glue_test_script" {
  bucket       = aws_s3_bucket.glue_scripts.id
  key          = "scripts/glue_test_script.py"
  source       = local_file.glue_test_script.filename
  content_type = "text/x-python"
  etag         = data.archive_file.glue_test_script_zip.output_md5
}

resource "aws_iam_role" "glue_job" {
  name = "${var.glue_job_role_base_name}-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_job.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_admin" {
  role       = aws_iam_role.glue_job.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_glue_job" "api_to_s3" {
  name              = "${var.glue_job_base_name}-${random_string.suffix.result}"
  role_arn          = aws_iam_role.glue_job.arn
  glue_version      = "5.0"
  max_retries       = 0
  timeout           = 2880
  number_of_workers = 2
  worker_type       = "G.1X"
  execution_class   = "STANDARD"

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/${aws_s3_object.glue_test_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-metrics"                   = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-auto-scaling"              = "true"
    "--TempDir"                          = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
    "--output_bucket"                    = aws_s3_bucket.pipeline_output.bucket
    "--api_source_url"                   = var.api_source_url
  }

  execution_property {
    max_concurrent_runs = 1
  }

  depends_on = [
    aws_s3_object.glue_test_script,
    aws_iam_role_policy_attachment.glue_service,
    aws_iam_role_policy_attachment.glue_admin
  ]
}
