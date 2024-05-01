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

  username_configuration {
    case_sensitive = false
  }

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
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
}
