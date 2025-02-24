#  IAM Role for Lambda
resource "aws_iam_role" "lambda_backup_role" {
  name = "LambdaBackupRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

#  Updated Policy for managing EBS snapshots & EC2 recovery (Added ec2:StopInstances, ec2:DetachVolume, ec2:AttachVolume)
resource "aws_iam_policy" "snapshot_management_policy" {
  name        = "SnapshotManagementPolicy"
  description = "Allows Lambda to create, delete, describe EBS snapshots, stop/start instances, detach/attach volumes, and launch new instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
          "ec2:CreateVolume",
          "ec2:AttachVolume",   
          "ec2:DetachVolume",   
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:StopInstances",  
          "ec2:StartInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::664418964175:role/LambdaBackupRole"
      }
    ]
  })
}

# Policy for storing backups in S3 Glacier
resource "aws_iam_policy" "s3_glacier_backup_policy" {
  name        = "S3GlacierBackupPolicy"
  description = "Allows Lambda to store backups in S3 Glacier"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::tatenda-backup-recovery-vault",
          "arn:aws:s3:::tatenda-backup-recovery-vault/*"
        ]
      }
    ]
  })
}

#  Policy for SNS Publish
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "SNSPublishPolicy"
  description = "Allows Lambda to publish messages to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = "arn:aws:sns:us-east-1:664418964175:backup-alerts-topic"
      }
    ]
  })
}

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "snapshot_policy_attachment" {
  role       = aws_iam_role.lambda_backup_role.name
  policy_arn = aws_iam_policy.snapshot_management_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_glacier_policy_attachment" {
  role       = aws_iam_role.lambda_backup_role.name
  policy_arn = aws_iam_policy.s3_glacier_backup_policy.arn
}

resource "aws_iam_role_policy_attachment" "sns_policy_attachment" {
  role       = aws_iam_role.lambda_backup_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}
