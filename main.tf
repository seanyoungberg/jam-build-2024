resource "aws_vpc" "vpc" {
  cidr_block = "10.2.0.0/16"
  tags = {
    "Name" = "CodeBuid-Torsten"
  }
}


# Create an S3 bucket to store the Terraform state file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "jamtest"

  # Enable versioning to keep track of changes in the state file
  versioning {
    enabled = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Production"
  }
}

# Optional: Enable server-side encryption for the state file (recommended)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # You can also use "aws:kms" if you want to use KMS
    }
  }
}

# Optional: Set a bucket policy to restrict access (replace the <your-aws-account-id> with your account ID)
resource "aws_s3_bucket_policy" "terraform_state_policy" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowRootAndAdminAccess",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::<your-aws-account-id>:root"
        },
        Action    = "s3:*",
        Resource  = [
          "arn:aws:s3:::${aws_s3_bucket.terraform_state.id}",
          "arn:aws:s3:::${aws_s3_bucket.terraform_state.id}/*"
        ]
      },
      {
        Sid       = "DenyUnencryptedUploads",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.terraform_state.id}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

# Configure the DynamoDB table for state locking (to avoid conflicts during concurrent operations)
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Backend configuration to store the state in the S3 bucket
terraform {
  backend "s3" {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key            = "path/to/terraform.tfstate"  # Path inside the bucket
    region         = "us-east-1"
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name  # For state locking
    encrypt        = true  # Encrypt the state file
  }
}