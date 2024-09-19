

# Create the S3 bucket to store the state
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = var.s3_bucket  # Replace this with a unique name for the S3 bucket

  # Enable versioning to allow state rollback
  versioning {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Dev"
  }
}

# (Optional) Create a DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = "Dev"
  }
}