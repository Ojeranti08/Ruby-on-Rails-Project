#aws configuration
#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#sudo yum -y install unzip && unzip awscliv2.zip
#sudo ./aws/install
#aws configure >> Enter IAM user credentials and access keys
# Terraform Block
terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Provider Block 
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}
