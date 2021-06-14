variable "AWS_ACCESS_KEY" {
default = "AKIASBQAQ2HC6GYXNPN7"
}
variable "AWS_SECRET_KEY" {
default = "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"
}
variable "AWS_REGION" {
default = "ap-south-1"
}
variable "ami-id"{
default = "ami-0ad704c126371a549"
}

variable "availability-zone" {
default = "ap-south-1a"
}

variable "Key-name"{
default = "task1-key"
}

variable "public-key" {
default ="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzXD5tF1G5oF3StxzKbT3TvwtL2P/ZotKFARLsZr7KEfaHU4ZPA3q3dcnkum67HpNV4p/v8EIIUFFsX2ZuxH2sN5UYKDm6WmPdII+vkc+JBE65/CiK2m5RJ7mwclgJpQuNdYdREzA79FX+ZFTyBlt/KMwb06wcgWonYPpWcVxujpIot2rag+ZA5TcR5KyZKSfdM7AlMLUHARPAKjo2ikmvccNSLxg2P6AJf7Epgb0rvfb3skv34w0EslQSZD/s/nSmNifcVSVXTKeggAUlIMC17Od+YwfUM0dFgQNpF54WJzvaRF2tFv5pMQFRr6qLQBNFoe8ezvz2b26m9gMAwX0l"
}

variable "aws-security-group-name" {
default = "task-security-group"
}
variable "my-cidr" {
    default = ["0.0.0.0/0"]
}
variable "volume-size" {
default = "5"
}


variable "aws-ebs-volume-name"{
default = "task-ebs-volume"
}
variable "aws-instance-type"{
default = "t2.micro"
}

variable "instance-name"{
default = "task6"
}

variable "vpc_id" {
default = "vpc-0e35d565"
}

variable "aws-bucket-name" {
default = "task-1-bucket-12345678912"
}

variable "my-role" {
default =  "task1-role"
}

variable "my-policy" {
default = "codepipeline_policy"
}

variable "pipeline" {
default = "code-pipeline"
}

variable "Owner" {
default="visheshgargavi"
}
variable "Repo" {
default="hybrid-task1"
}
variable "Branch" {
default="master"
}
variable "Oauth-token" {
default="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"
}