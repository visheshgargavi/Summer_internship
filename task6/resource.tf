resource "aws_key_pair" "task1-key" {
  key_name    = var.Key-name
  public_key  = var.public-key 
}

resource "aws_security_group" "task1-sg" {
  name        = var.aws-security-group-name
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my-cidr
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.my-cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.my-cidr
  }

  tags = {
    Name = var.aws-security-group-name
  }
}

resource "aws_ebs_volume" "task1-ebs" {
  availability_zone = var.availability-zone
  size              = var.volume-size

  tags = {
    Name = var.aws-ebs-volume-name
  }
}

resource "aws_instance" "task1-inst" {
  ami           = var.ami-id
  instance_type = var.aws-instance-type
  availability_zone = var.availability-zone
  key_name      = "saketsir"
  security_groups = [ var.aws-security-group-name ]
  user_data = <<-EOF
                #! /bin/bash
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo yum install git -y
                mkfs.ext4 /dev/xvdf1
                mount /dev/xvdf1 /var/www/html
                cd /var/www/html
                git clone https://github.com/visheshgargavi/hybrid-task1
                
  EOF

  tags = {
    Name = var.instance-name
  }
}

resource "aws_volume_attachment" "task1-attach" {
 device_name = "/dev/sdf"
 volume_id = "${aws_ebs_volume.task1-ebs.id}"
 instance_id = "${aws_instance.task1-inst.id}"
}

data "aws_canonical_user_id" "current_user" {}

resource "aws_s3_bucket" "my-test-s3-terraform-bucket-vishesh1" {
  bucket = var.aws-bucket-name
    versioning {
    enabled = false
  }
  grant {
    id          = "${data.aws_canonical_user_id.current_user.id}"
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL",]
  }

  grant {
    permissions = ["READ_ACP",]
    type        = "Group"
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
  }

  tags = {
    Name = var.aws-bucket-name
  }
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.bucket_regional_domain_name}"
    origin_id   = "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.id}"

  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "S3 bucket"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.id}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }


  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [
   aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1
]
}

resource "aws_iam_role" "codepipeline_role" {
  name = var.my-role

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = var.my-policy
  #role = "${aws_iam_role.codepipeline_role.id}"

 policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.arn}",
        "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lifecycle" {
  name       = "tf-iam-role-attachment-lifecycle"
  roles      = ["${aws_iam_role.codepipeline_role.name}"]
  policy_arn = "${aws_iam_policy.codepipeline_policy.arn}"
}

resource "aws_codepipeline" "codepipeline" {
  name     = var.pipeline
  role_arn = "${aws_iam_role.codepipeline_role.arn}"


   artifact_store {
    location = "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.bucket}"
    type     = "S3"
	}
	 
	 stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifacts"]
configuration = {
        Owner  = var.Owner
        Repo   = var.Repo
        Branch = var.Branch
	OAuthToken = var.Oauth-token       
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["SourceArtifacts"]	
		configuration = {
        BucketName = "${aws_s3_bucket.my-test-s3-terraform-bucket-vishesh1.bucket}"
        Extract = "true"
      }
      
}
}
}

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "chrome ${aws_cloudfront_distribution.s3_distribution.domain_name}/Screenshot+(609).png"
  	}
}