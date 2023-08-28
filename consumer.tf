module "consumer_docker_image" {
    source = "terraform-aws-modules/lambda/aws//modules/docker-build"

    create_ecr_repo = true
    ecr_repo = var.consumer_ecr_repo
    image_tag       = "latest"
    source_path = abspath(var.consumer_lambda_source_path)
}

resource "aws_lambda_function" "consumer_lambda" {
    function_name = var.consumer_lambda_function_name

    package_type = "Image"
    image_uri = module.consumer_docker_image.image_uri
    #image_uri = "022162415430.dkr.ecr.eu-north-1.amazonaws.com/blender-lambda-consumer:latest"
    role = aws_iam_role.lambda_exec.arn
    timeout = var.consumer_timeout_seconds
    memory_size = 3009

    ephemeral_storage {
        size = 10240
    }

    environment {
        variables = {
            "QUEUE_NAME" = aws_sqs_queue.queue.name,
            "S3_BUCKET_NAME" = aws_s3_bucket.lambda_bucket.id,
        }
    }
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
    event_source_arn = aws_sqs_queue.queue.arn
    enabled = true
    function_name = aws_lambda_function.consumer_lambda.arn
    batch_size = 1
}


resource "aws_cloudwatch_log_group" "consumer_lambda_log_group" {
    name = "/aws/lambda/${aws_lambda_function.consumer_lambda.function_name}"

    retention_in_days = 30
}