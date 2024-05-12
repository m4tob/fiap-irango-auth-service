variable "client_id" {
  default = "6lhlkkfbfb4q5kpp90urffae"
}

variable "lambda_login_runtime" {
  default = "nodejs20.x"
}

# Secrets
variable "DB_USERNAME" {
  type = string
}

variable "DB_PASSWORD" {
  type = string
}
