# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "iam_for_lambda" {
#   name               = "login_iam_for_lambda"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

data "archive_file" "login_artefact" {
  type        = "zip"
  source_dir = "${local.lambdas_path}/login"
  output_path = "files/login_lambda_function_payload.zip"
}

resource "aws_lambda_function" "login_lambda" {
  filename      = "files/login_lambda_function_payload.zip"
  function_name = "${var.lambda_name}"
  role          = "arn:aws:iam::364764462991:role/LabRole"
  handler       = "index.handler"
  timeout       =  15
  memory_size   = 128
  source_code_hash = data.archive_file.login_artefact.output_base64sha256
  depends_on    = [aws_cloudwatch_log_group.lambda_log_group]

  runtime = "nodejs20.x"

  vpc_config {
    subnet_ids         = [data.terraform_remote_state.infra.outputs.subnet_private_a_id,
    data.terraform_remote_state.infra.outputs.subnet_private_b_id]
    security_group_ids = [data.terraform_remote_state.infra.outputs.aws_security_group_db_id]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-cache"
  }
  environment {
    variables = {
      PGUSER = "${data.terraform_remote_state.database.outputs.aws_db_username}",
      PGHOST = "${data.terraform_remote_state.database.outputs.aws_db_instance_endpoint}",
      PGPASSWORD = "${data.terraform_remote_state.database.outputs.aws_db_password}",
      PGDATABASE = "${data.terraform_remote_state.database.outputs.aws_db_name}",
      PGPORT = "3306",
    }
  }
}