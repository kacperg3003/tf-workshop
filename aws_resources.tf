#############################
#           S3              #
#############################

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "workshop-bucket-999"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access" {
  bucket = aws_s3_bucket.s3_bucket.id

  # 🚩 WORKSHOP EXERCISE: Change both to true to prevent data leaks.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "workshop-log-bucket-999"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "log_public" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "log_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_encryption" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.s3_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_sns_topic" "s3_events" {
  name              = "s3-event-topic"
  kms_master_key_id = aws_kms_key.s3_key.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_bucket.id
  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

#############################
#           EC2             #
#############################

resource "aws_iam_role" "ec2_role" {
  name = "workshop-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "workshop-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "ec2_instance" {
  ami = "ami-01e444924a2233b2d"

  # 🚩 WORKSHOP EXERCISE: Attendees update var.aws_ec2_type from "c5.18xlarge" 
  # to "t3.medium" in variables.tf to right-size the WordPress host.
  instance_type = var.aws_ec2_type

  iam_instance_profile = aws_iam_instance_profile.profile.name

  vpc_security_group_ids = [
    aws_security_group.ec2_instance_sg.id
  ]

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }
}

resource "aws_security_group" "ec2_instance_sg" {
  name        = "allow-ssh"
  description = "Enable SSH access to EC2 instance"

  ingress {
    description = "Allow aadmin SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # 🚩 WORKSHOP EXERCISE: Change from ["0.0.0.0/0"] to a trusted CIDR like ["10.0.0.1/32"]
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}