variable "resource_prefix" {
  default = "fiap-irango"
}

variable "region" {
  default = "us-east-1"
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "default_az" {
  default = "us-east-1a"
}

variable "client_id" {
  default = "6lhlkkfbfb4q5kpp90urffae"
}

variable "lambda_name" {
  default = "lambda_function_login"
}