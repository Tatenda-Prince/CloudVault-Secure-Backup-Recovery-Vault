resource "aws_cloudwatch_event_rule" "backup_schedule" {
  name                = "daily-backup"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "backup_lambda_target" {
  rule      = aws_cloudwatch_event_rule.backup_schedule.name
  arn       = aws_lambda_function.backup_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_schedule.arn
}

resource "aws_cloudwatch_event_rule" "ec2_failure_rule" {
  name        = "ec2-failure-detection"
  description = "Triggers when EC2 instance fails"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["stopped", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "recovery_lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_failure_rule.name
  arn       = aws_lambda_function.recovery_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge_recovery" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recovery_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_failure_rule.arn
}
