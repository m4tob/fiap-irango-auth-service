terraform {
  required_version = ">= 1.7.4, <= 1.8.1"

  backend "s3" {
    bucket = "fiap-irango-tfstate"
    key    = "fiap-irango-auth-service.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43.0"
    }
  }
}

provider "aws" {
  region = data.terraform_remote_state.infra.outputs.region

  default_tags {
    tags = {
      Environment = data.terraform_remote_state.infra.outputs.environment
      Service     = data.terraform_remote_state.infra.outputs.resource_prefix
    }
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "fiap-irango-tfstate"
    key    = "fiap-irango-infra.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"
  config = {
    bucket = "fiap-irango-tfstate"
    key    = "fiap-irango-database.tfstate"
    region = "us-east-1"
  }
}
