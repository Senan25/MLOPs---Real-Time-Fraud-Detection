
# ==========================================
# S3 BUCKET - FRAUD DETECTION DATA
# ==========================================

resource "aws_s3_bucket" "fraud_detection_data" {
  bucket = var.s3_bucket_name

  force_destroy = false

  tags = {
    Name        = "fraud-detection-data"
    Environment = "production"
    Project     = "Real-Time-Fraud-Detection"
    ManagedBy   = "Terraform"
  }
}

# ==========================================
# BUCKET OWNERSHIP
# ==========================================

resource "aws_s3_bucket_ownership_controls" "fraud_detection_data" {
  bucket = aws_s3_bucket.fraud_detection_data.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ==========================================
# BLOCK PUBLIC ACL ACCESS
# ==========================================

resource "aws_s3_bucket_public_access_block" "fraud_detection_data" {
  bucket = aws_s3_bucket.fraud_detection_data.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ==========================================
# SERVER-SIDE ENCRYPTION
# ==========================================

resource "aws_s3_bucket_server_side_encryption_configuration" "fraud_detection_data" {
  bucket = aws_s3_bucket.fraud_detection_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==========================================
# IP-RESTRICTED BUCKET POLICY
# ==========================================

data "aws_iam_policy_document" "fraud_detection_data" {

  # Allow object downloads only from approved IP ranges
  statement {
    sid    = "AllowReadFromApprovedIPs"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.fraud_detection_data.arn}/*"
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.s3_allowed_ipv4_cidrs
    }
  }

  # Require HTTPS for all S3 operations
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.fraud_detection_data.arn,
      "${aws_s3_bucket.fraud_detection_data.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "fraud_detection_data" {
  bucket = aws_s3_bucket.fraud_detection_data.id
  policy = data.aws_iam_policy_document.fraud_detection_data.json

  depends_on = [
    aws_s3_bucket_public_access_block.fraud_detection_data
  ]
}
