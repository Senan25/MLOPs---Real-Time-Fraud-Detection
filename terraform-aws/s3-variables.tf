
variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name"

  type    = string
  default = "real-time-fraud-detection-data-565950323291"
}

variable "s3_allowed_ipv4_cidrs" {
  description = "IPv4 CIDR ranges allowed to download S3 objects"

  type = list(string)

  default = [
    "91.209.225.0/24"
  ]
}
