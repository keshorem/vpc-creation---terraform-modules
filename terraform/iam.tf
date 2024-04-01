resource "aws_iam_role" "aws_role_creation" {
    name = "aws_role_creation"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { 
                Service = "ec2.amazonaws.com"
            }
        },
    ]
    })

    tags = {
        Name = "Terraform VPC"
    }
}

resource "aws_iam_instance_profile" "ec2_instance_profile"{
    name = "ec2_instance_profile"
    role = aws_iam_role.aws_role_creation.name
}