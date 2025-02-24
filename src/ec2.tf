# ✅ Fetch the existing subnet (DO NOT create it)
data "aws_subnet" "selected_subnet" {
  id = "subnet-05331c659ceec14e5"  # Ensure this subnet actually exists
}

# ✅ Fetch the VPC associated with the subnet
data "aws_vpc" "selected_vpc" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

# ✅ Security Group - Ensures it's in the same VPC as subnet
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-backup-sg"
  description = "Allow limited SSH access"
  vpc_id      = data.aws_vpc.selected_vpc.id  

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.185.138.227/32"]  # Replace with your actual IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2BackupRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# ✅ IAM Policy for EC2 to Write to S3 and Publish SNS
resource "aws_iam_policy" "ec2_policy" {
  name        = "EC2BackupPolicy"
  description = "Policy to allow EC2 access to S3 and SNS"
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": ["arn:aws:s3:::your-s3-bucket-name/*"]
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "*"
    }
  ]
}
EOF
}

# ✅ Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# ✅ Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# ✅ EC2 Instance
resource "aws_instance" "ec2_instance" {
  ami                    = "ami-05b10e08d247fb927"  
  instance_type          = "t2.micro"
  key_name               = "ashleyKeypair"  
  subnet_id              = data.aws_subnet.selected_subnet.id  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]  
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name  

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true  
  }

  tags = {
    Name = "Backup-Prod-EC2"
  }

  depends_on = [aws_iam_instance_profile.ec2_instance_profile] 
}

# ✅ EBS Volume in same AZ as EC2
resource "aws_ebs_volume" "backup_volume" {
  availability_zone = aws_instance.ec2_instance.availability_zone  
  size             = 10  
  type             = "gp3"

  tags = {
    Name = "BackupVolume"
  }
}

# ✅ Attach the EBS volume to EC2
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.backup_volume.id
  instance_id = aws_instance.ec2_instance.id

  depends_on = [aws_instance.ec2_instance, aws_ebs_volume.backup_volume]
}

# ✅ Ensure Security Group is destroyed last
resource "aws_security_group" "ec2_sg-tatenda" {
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_instance.ec2_instance]  # Ensures EC2 is destroyed first
}
