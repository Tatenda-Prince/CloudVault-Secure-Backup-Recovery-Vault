resource "aws_lambda_function" "recovery_lambda" {
  function_name    = "ebs-recovery-lambda"
  role            = aws_iam_role.lambda_backup_role.arn
  handler         = "recovery_lambda.lambda_handler"
  runtime         = "python3.9"

  filename         = "recovery_lambda.zip"
  source_code_hash = filebase64sha256("recovery_lambda.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN    = aws_sns_topic.backup_sns.arn
      INSTANCE_TYPE    = "t2.micro"
      KEY_NAME         = "ashleyKeypair"  # Replace with your actual key pair name
      SECURITY_GROUP   = aws_security_group.ec2_sg.id
      SUBNET_ID        = aws_subnet.default.id
      AVAILABILITY_ZONE = "us-east-1a"  # Add this to fix KeyError issue
    }
  }
}

resource "aws_lambda_function" "backup_lambda" {
  function_name    = "ebs-backup-lambda"
  role            = aws_iam_role.lambda_backup_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.backup_sns.arn
      S3_BUCKET     = aws_s3_bucket.backup_bucket.id
    }
  }
}




