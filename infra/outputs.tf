output "aws_region" {
  value = data.aws_region.current.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "random_suffix" {
  value = random_string.suffix.result
}

output "glue_scripts_bucket_name" {
  value = aws_s3_bucket.glue_scripts.id
}

output "glue_scripts_bucket_arn" {
  value = aws_s3_bucket.glue_scripts.arn
}

output "glue_scripts_bucket_domain_name" {
  value = aws_s3_bucket.glue_scripts.bucket_domain_name
}

output "glue_scripts_bucket_regional_domain_name" {
  value = aws_s3_bucket.glue_scripts.bucket_regional_domain_name
}

output "pipeline_output_bucket_name" {
  value = aws_s3_bucket.pipeline_output.id
}

output "pipeline_output_bucket_arn" {
  value = aws_s3_bucket.pipeline_output.arn
}

output "pipeline_output_bucket_domain_name" {
  value = aws_s3_bucket.pipeline_output.bucket_domain_name
}

output "pipeline_output_bucket_regional_domain_name" {
  value = aws_s3_bucket.pipeline_output.bucket_regional_domain_name
}

output "glue_test_script_s3_uri" {
  value = "s3://${aws_s3_bucket.glue_scripts.bucket}/${aws_s3_object.glue_test_script.key}"
}

output "glue_test_script_key" {
  value = aws_s3_object.glue_test_script.key
}

output "glue_job_name" {
  value = aws_glue_job.api_to_s3.id
}

output "glue_job_arn" {
  value = aws_glue_job.api_to_s3.arn
}

output "glue_job_role_name" {
  value = aws_iam_role.glue_job.name
}

output "glue_job_role_arn" {
  value = aws_iam_role.glue_job.arn
}

output "api_source_url" {
  value = var.api_source_url
}
