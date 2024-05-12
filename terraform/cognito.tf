# resource "aws_iam_saml_provider" "default" {
#   name                   = "my-saml-provider"
#   saml_metadata_document = file("saml-metadata.xml")
# }

# resource "aws_cognito_identity_pool" "main" {
#   identity_pool_name               = "identity pool"
#   allow_unauthenticated_identities = false
#   allow_classic_flow               = false


#   cognito_identity_providers {
#     # client_id               = "${var.client_id}"
#     # provider_name           = "cognito-idp.us-east-1.amazonaws.com/us-east-1_Tv0493apJ"
#     server_side_token_check = false
#   }


#   saml_provider_arns           = [aws_iam_saml_provider.default.arn]
# }

resource "aws_cognito_user_pool" "default" {
  name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-cognito-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
  }
  username_configuration {
    case_sensitive = false
  }

  lambda_config {
    pre_sign_up = aws_lambda_function.confirm_user.arn
  }

  depends_on = [aws_lambda_function.confirm_user]
  password_policy {
    minimum_length    = 11
    require_lowercase = false
    require_numbers   = false
    require_uppercase = false
    require_symbols   = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "cpf"
    required                 = false

    string_attribute_constraints {
      min_length = 11
      max_length = 11
    }
  }


  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-cognito-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "default" {
  name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-cognito-user-pool-client"

  user_pool_id                  = aws_cognito_user_pool.default.id
  generate_secret               = false
  refresh_token_validity        = 90
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

resource "aws_lambda_permission" "cognito_trigger" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.confirm_user.arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.default.arn
}

resource "aws_cognito_user" "not_identified" {
  user_pool_id = aws_cognito_user_pool.default.id
  username     = var.username_not_identified
  password     = var.password_not_identified

  depends_on = [aws_lambda_permission.cognito_trigger]

  attributes = {
    cpf            = null
    email          = var.email_not_identified
    email_verified = true
  }
}
