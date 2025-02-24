resource "aws_cloudwatch_metric_alarm" "ec2_status_alarm" {
  alarm_name          = "ec2-instance-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_System"
  namespace          = "AWS/EC2"
  period             = 300
  statistic          = "Minimum"
  threshold          = 0
  alarm_description  = "Triggers if EC2 fails system status checks"
  actions_enabled    = true
  alarm_actions      = [aws_sns_topic.backup_sns.arn]

  dimensions = {
    InstanceId = aws_instance.ec2_instance.id
  }
}

