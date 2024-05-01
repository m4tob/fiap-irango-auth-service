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

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  
  retention_in_days = 1
  lifecycle {
    prevent_destroy = false
  }
}

data "archive_file" "login_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/login"
  output_path = "files/login_lambda_function_payload.zip"
}

resource "aws_lambda_function" "login_lambda" {
  filename         = "files/login_lambda_function_payload.zip"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  timeout          = 15
  memory_size      = 128
  source_code_hash = data.archive_file.login_artefact.output_base64sha256
  depends_on       = [
    aws_cloudwatch_log_group.lambda_log_group,
  ]

  runtime = var.lambda_login_runtime

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [ aws_security_group.lambda.id ]
  }

  environment {
    variables = {
      PGHOST     = "${data.terraform_remote_state.database.outputs.aws_db_instance_host}",
      PGPORT     = 3306,
      PGDATABASE = "${data.terraform_remote_state.database.outputs.db_name}",
      PGUSER     = "${var.db_user}",
      PGPASSWORD = "${var.db_password}",
    }
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  }
}
