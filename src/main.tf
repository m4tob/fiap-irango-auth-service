terraform {
  required_version = "~> 1.7.4"

  backend "local" { path = "../../tfstate/fiap-irango-database.tfstate" }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43.0"
    }
  }
}

provider "aws" {
  region  = data.terraform_remote_state.infra.outputs.region
}

data "terraform_remote_state" "infra" {
  backend = "local"
  config = { path = "../../tfstate/fiap-irango-infra.tfstate" }
}