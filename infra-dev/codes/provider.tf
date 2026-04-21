terraform {

  backend "s3" {
    bucket = "projeto-docker-terraform-state"
    key    = "infra-dev/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
  }

  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}