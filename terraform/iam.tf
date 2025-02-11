#####################
#Extract lambda to s3 policy documents and roles
#####################

resource "aws_iam_role" "lambda_role" {
  name_prefix        = "role-de-rossolimo-lambdas-"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

data "aws_iam_policy_document" "s3_document" {
  statement {

    actions = [ "s3:PutObject", "s3:GetObject", "s3:ListBucket" ]

    resources = [
      "${aws_s3_bucket.data_bucket.arn}/*",
      "${aws_s3_bucket.code_bucket.arn}/*",
      "${aws_s3_bucket.processed_data_bucket.arn}/*",

    ]
  }
}


resource "aws_iam_policy" "s3_policy" {
  name_prefix = "s3-policy-ingestion-lambda-"
  policy      = data.aws_iam_policy_document.s3_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}


#####################
#cloudwatch policy and role (and attachment to extract lambda)
#####################


data "aws_iam_policy_document" "cw_document" {
  statement {
    effect = "Allow"
        
    actions = [ "logs:CreateLogGroup"]

    resources =  ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
     effect = "Allow"
      actions = [ "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:FilterLogEvents" ]
      resources = [ "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/extract-de_rossolimo:*", 
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/transform-de_rossolimo:*",
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/load-de_rossolimo:*"]

  }
}


# Create
resource "aws_iam_policy" "cw_policy" {
  name_prefix = "cw-policy-extract-de_rossolimo-"
  policy = data.aws_iam_policy_document.cw_document.json
}

# Attach
resource "aws_iam_role_policy_attachment" "lambda_cw_policy_attachment" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cw_policy.arn
}


#allows lambda to access secrets
resource "aws_iam_role_policy" "sm_policy" {
  name = "sm_access_permissions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


##############################
#transform lambda IAM roles and permissions
##############################

resource "aws_iam_role" "transform_lambda_role" {
  name_prefix        = "role-de-rossolimo-transform-lambdas-"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}


data "aws_iam_policy_document" "transform_s3_doc" {
  statement {
    effect = "Allow"

    actions = [ "s3:*" ]

    resources = [ 
    "${aws_s3_bucket.data_bucket.arn}",
    "${aws_s3_bucket.processed_data_bucket.arn}",
    "${aws_s3_bucket.processed_data_bucket.arn}",
    ]
  }
  statement{
  effect = "Allow"
  actions = [ "s3:*" ]
    resources = [
      "${aws_s3_bucket.data_bucket.arn}/*",
      "${aws_s3_bucket.code_bucket.arn}/*",
      "${aws_s3_bucket.processed_data_bucket.arn}/*",
    ]
  }
}

#create
resource "aws_iam_policy" "transform_s3_policy" {
  name_prefix = "s3-policy-transform-lambda-"
  policy      = data.aws_iam_policy_document.transform_s3_doc.json
}

# Attach
resource "aws_iam_role_policy_attachment" "transform_lambda_s3_policy_attachment" {
  role = aws_iam_role.transform_lambda_role.name
  policy_arn = aws_iam_policy.transform_s3_policy.arn
}

###########################
#transform lambda cloudwatch policy and attachment
###########################

# attaches transform_lambda to cloudwatch policy (same as extract CW policy)
resource "aws_iam_role_policy_attachment" "transform_lambda_cw_policy_attachment" {
  role = aws_iam_role.transform_lambda_role.name
  policy_arn = aws_iam_policy.cw_policy.arn
}

#attaches secrets manager policy to lambda transform
resource "aws_iam_role_policy" "sm_transform_policy" {
  name = "sm_access_permissions"
  role = aws_iam_role.transform_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

#####################
#load lambda to s3 policy documents and roles
#####################

resource "aws_iam_role" "load_lambda_role" {
  name_prefix        = "load-role-de-rossolimo-lambdas-"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}


data "aws_iam_policy_document" "load_s3_document" {
  statement {

    actions = [ "s3:PutObject", "s3:GetObject", "s3:ListBucket" ]

    resources = [
      "${aws_s3_bucket.code_bucket.arn}/*",
      "${aws_s3_bucket.processed_data_bucket.arn}/*",

    ]
  }
  
  statement{
    actions = [ "s3:PutObject", "s3:GetObject", "s3:ListBucket" ]

    resources = [
      "${aws_s3_bucket.code_bucket.arn}",
      "${aws_s3_bucket.processed_data_bucket.arn}",
    ]
  }
}

resource "aws_iam_policy" "load_s3_policy" {
  name_prefix = "load-s3-policy-lambda-"
  policy      = data.aws_iam_policy_document.load_s3_document.json
}

resource "aws_iam_role_policy_attachment" "load_lambda_s3_policy_attachment" {
  role       = aws_iam_role.load_lambda_role.name
  policy_arn = aws_iam_policy.load_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "load_lambda_cw_policy_attachment" {
  role = aws_iam_role.load_lambda_role.name
  policy_arn = aws_iam_policy.cw_policy.arn
}

#allows load lambda to access secrets
resource "aws_iam_role_policy" "load_sm_policy" {
  name = "load_sm_access_permissions"
  role = aws_iam_role.load_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

