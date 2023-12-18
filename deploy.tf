provider "aws" {
  region = "eu-central-1"
  access_key = "AKIAWAKSONSC2XHE5NO2"
  secret_key = "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"

}

data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "./"
  output_path = "weatherdata/script.zip"
  excludes    = [".terraform/", ".terraform.lock.hcl", "terraform.tfstate"]
}
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = "weather-data-shekar"
}

resource "aws_s3_object" "lambda_code_object" {
  bucket = aws_s3_bucket.lambda_code_bucket.bucket
  key    = "script.zip"
  source = data.archive_file.lambda_code.output_path
}

resource "aws_lambda_function" "api_aggregation_lambda" {
  function_name = "api_aggregation_lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 90

  source_code_hash = filebase64(data.archive_file.lambda_code.output_path)
  # Specify the S3 bucket and object storing the deployment
  s3_bucket = aws_s3_bucket.lambda_code_bucket.bucket
  s3_key    = aws_s3_object.lambda_code_object.key
  role = aws_iam_role.lambda_execution_role.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_aggregation_lambda.function_name
  principal = "apigateway.amazonaws.com"
}
