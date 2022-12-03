terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_s3_bucket" "raw" {
  bucket = "fraud-detection-app-raw"
}

resource "aws_s3_bucket" "standardized" {
  bucket = "fraud-detection-app-standardized"
}

resource "aws_s3_bucket" "features" {
  bucket = "fraud-detection-app-feature-store"
}

resource "aws_s3_bucket" "code" {
  bucket = "fraud-detection-app-code"
}

resource "aws_s3_bucket" "logs" {
  bucket = "fraud-detection-app-logs"
}

resource "aws_api_gateway_rest_api" "fraud-detection-api" {
  body = openapi.yaml

  name = "fraud-detection-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "fraud-detection-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.example.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api-stage" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = "fraud-detection-stage"
}

resource "aws_kinesis_stream" "test_stream" {
  name             = "terraform-kinesis-test"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

# Kinesis stream

resource "aws_kinesis_stream" "pipeline1" {
  name             = "terraform-kinesis-test"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

# TODO: Add execution role for kinesis

# Kinesis data analytics
resource "aws_s3_object" "flink-example1" {
  bucket = aws_s3_bucket.fraud-detection-code.bucket
  key    = "example-flink-application1"
  source = "flink-example1.jar"
}

resource "aws_kinesisanalyticsv2_application" "pipeline1" {
  name                   = "example-flink-application"
  runtime_environment    = "FLINK-1_15"
  service_execution_role = aws_iam_role.example.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.fraud-detection-code.arn
          file_key   = aws_s3_object.flink-example1.key
        }
      }

      code_content_type = "ZIPFILE"
    }
  }
}

# Kinesis data analytics
resource "aws_s3_object" "flink-example2" {
  bucket = aws_s3_bucket.fraud-detection-code.bucket
  key    = "example-flink-application2"
  source = "flink-example1.jar"
}

resource "aws_kinesisanalyticsv2_application" "pipeline2" {
  name                   = "example-flink-application2"
  runtime_environment    = "FLINK-1_15"
  service_execution_role = aws_iam_role.example.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.fraud-detection-code.arn
          file_key   = aws_s3_object.flink-example2.key
        }
      }

      code_content_type = "ZIPFILE"
    }
  }
}