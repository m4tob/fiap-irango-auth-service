variable "client_id" {
  default = "6lhlkkfbfb4q5kpp90urffae"
}

variable "lambda_login_runtime" {
  default = "nodejs20.x"
}


variable "lambda_confirm_user_runtime" {
  default = "nodejs20.x"
}

# Secrets
variable "DB_USERNAME" {
  type = string
}

variable "DB_PASSWORD" {
  type = string
}

variable "username_not_identified" {
  default = "no-reply@fiapirango.com"
}

variable "password_not_identified" {
  default = "password_not_identified"
}

variable "email_not_identified" {
  default = "no-reply@fiapirango.com"
}

