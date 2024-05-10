# data "aws_iam_policy_document" "assume_role_lambda" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }

#     actions = [
#       "sts:AssumeRole"
#     ]
#   }
# }

resource "aws_iam_role" "lambda_auto_confirm_user" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRoleCon" {
  role       = aws_iam_role.lambda.name
    # role             = "arn:aws:iam::364764462991:role/LabRole"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRoleCon" {
  role       = aws_iam_role.lambda.name
    # role             = "arn:aws:iam::364764462991:role/LabRole"

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_lambda_auto_confirm_user_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambdas/autoConfirmUser"
  output_path = "files/lambda_auto_confirm_user_lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda_auto_confirm_user" {
  function_name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-lambda_auto_confirm_user"
  filename      = "files/lambda_auto_confirm_user_lambda_function_payload.zip"
  role          = aws_iam_role.lambda_auto_confirm_user.arn
  # role             = "arn:aws:iam::364764462991:role/LabRole"
  handler          = "index.handler"
  timeout          = 5
  memory_size      = 128
  source_code_hash = data.archive_file.lambda_lambda_auto_confirm_user_artefact.output_base64sha256
  runtime = var.lambda_lambda_auto_confirm_user_runtime

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  }
}
