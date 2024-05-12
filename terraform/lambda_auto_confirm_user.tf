resource "aws_security_group" "lambda_confirm_user" {
  name        = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda-confirm-user"
  description = "inbound: all + outbound: all"
  vpc_id      = data.terraform_remote_state.infra.outputs.aws_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda-confirm-user"
  }
}

resource "aws_iam_role" "lambda_confirm_user" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-confirm-user"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_cloudwatch_log_group" "lambda_confirm_user" {
  name = "/aws/lambda/${aws_lambda_function.confirm_user.function_name}"

  retention_in_days = 1
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRoleCon" {
  role = aws_iam_role.lambda_confirm_user.name
  # role             = "arn:aws:iam::364764462991:role/LabRole"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRoleCon" {
  role = aws_iam_role.lambda_confirm_user.name
  # role             = "arn:aws:iam::364764462991:role/LabRole"

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_confirm_user_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambdas/autoConfirmUser"
  output_path = "files/confirm_user_lambda_function_payload.zip"
}

resource "aws_lambda_function" "confirm_user" {
  function_name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-confirm-user"
  filename      = "files/confirm_user_lambda_function_payload.zip"
  role          = aws_iam_role.lambda_confirm_user.arn
  # role             = "arn:aws:iam::364764462991:role/LabRole"
  runtime          = var.lambda_confirm_user_runtime
  source_code_hash = data.archive_file.lambda_confirm_user_artefact.output_base64sha256
  handler          = "index.handler"
  timeout          = 5
  memory_size      = 128
  depends_on       = []

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [aws_security_group.lambda_confirm_user.id]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-confirm-user"
  }
}
