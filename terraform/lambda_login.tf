resource "aws_security_group" "lambda" {
  name        = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda"
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
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda"
  }
}

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.login.function_name}"

  retention_in_days = 1
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_login_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambdas/login"
  output_path = "files/login_lambda_function_payload.zip"
}

resource "aws_lambda_function" "login" {
  function_name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-login"
  filename      = "files/login_lambda_function_payload.zip"
  role          = aws_iam_role.lambda.arn
  # role             = "arn:aws:iam::364764462991:role/LabRole"
  handler          = "index.handler"
  timeout          = 5
  memory_size      = 128
  source_code_hash = data.archive_file.lambda_login_artefact.output_base64sha256
  depends_on = [
    # aws_cognito_user_pool.default,
    # aws_cognito_user_pool_client.default
  ]

  runtime = var.lambda_login_runtime

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOSTNAME = "${split(":", data.terraform_remote_state.database.outputs.aws_db_instance_endpoint)[0]}",
      DB_PORT     = split(":", data.terraform_remote_state.database.outputs.aws_db_instance_endpoint)[1],
      DB_DATABASE = "${data.terraform_remote_state.database.outputs.db_name}",
      DB_USERNAME = "${var.DB_USERNAME}",
      DB_PASSWORD = "${var.DB_PASSWORD}" #,
      # USER_POOL_ID = "${aws_cognito_user_pool.default.id}",
      # CLIENT_ID = "${aws_cognito_user_pool_client.id}",
    }
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  }
}
