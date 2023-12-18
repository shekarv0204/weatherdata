provider "aws" {
  region = "eu-central-1"
}

data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "weatherdata/script"
  output_path = "weatherdata/script.zip"
}
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = "your-lambda-code-bucket-name"
  acl    = "private"
}

resource "aws_s3_bucket_object" "lambda_code_object" {
  bucket = aws_s3_bucket.lambda_code_bucket.bucket
  key    = "lambda_code.zip"
  source = data.archive_file.lambda_code.output_path
  acl    = "private"
}

resource "aws_lambda_function" "api_aggregation_lambda" {
  function_name = "api_aggregation_lambda"
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.8"
  timeout      = 60

  filename      = "weatherdata/script.zip"
  source_code_hash = filebase64(data.archive_file.lambda_code.output_path)
  # Specify the S3 bucket and object storing the deployment
  s3_bucket = aws_s3_bucket.lambda_code_bucket.bucket
  s3_key    = aws_s3_bucket_object.lambda_code_object.key

  role = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = {
      API_URL = "https://api.open-meteo.com/v1/forecast?latitude=51.5085&amp;longitude=-0.1257&amp;hourly=temperature_2m,rain,showers,visibility&amp;past_days=31"
    }
  }
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
