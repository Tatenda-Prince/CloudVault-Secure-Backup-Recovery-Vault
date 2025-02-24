terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" 
}


