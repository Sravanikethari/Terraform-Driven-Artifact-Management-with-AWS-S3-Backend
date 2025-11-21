terraform {
  backend "s3" {
    bucket = "amazn-s3-bucket-ksn" # Replace with your actual S3 bucket name
    key    = "Jenkins/terraform.tfstate"
    region = "us-east-1"
  }
}
