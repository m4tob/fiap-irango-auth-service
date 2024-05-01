variable "client_id" {
  default = "6lhlkkfbfb4q5kpp90urffae"
}

variable "lambda_name" {
  default = "lambda_function_login"
}

variable "lambda_login_runtime" {
  default = "nodejs20.x"
}

# Secrets
variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}
