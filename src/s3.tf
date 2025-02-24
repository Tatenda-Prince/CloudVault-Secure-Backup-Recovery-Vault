resource "aws_s3_bucket" "backup_bucket" {
  bucket = "tatenda-backup-recovery-vault"

  tags = {
    Name        = "Backup Recovery Vault"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_lifecycle" {
  bucket = aws_s3_bucket.backup_bucket.id

  rule {
    id     = "MoveToGlacier"
    status = "Enabled"

    transition {
      days          = 1
      storage_class = "GLACIER"
    }
  }
}

