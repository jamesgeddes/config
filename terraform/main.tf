terraform {
  backend "s3" {
    encrypt = true
#    bucket  = specified during CI
#    key     = specified during CI
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }
  }
}
