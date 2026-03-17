terraform {
  backend "s3" {
    bucket = "uv-state-files"
    key    = "statefile-s3drop/terraform.tfstate"
    region = "us-east-1"
  }
}