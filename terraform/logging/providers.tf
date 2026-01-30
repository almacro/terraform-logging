terraform {  
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 6.28"
    }
  }
  required_version = ">= 1.5.7"
}

provider "aws" {
  region = var.aws_region
}
