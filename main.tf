provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content              = tls_private_key.jenkins.private_key_pem
  filename             = "${path.module}/jenkins.pem"
  file_permission      = "0400"
  directory_permission = "0700"
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins"
  public_key = tls_private_key.jenkins.public_key_openssh
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins"
  description = "Allow HTTP, HTTPS, Jenkins, and SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_ec2" {
  ami                         = "ami-08a6efd148b1f7504" # Amazon Linux 2023
  instance_type               = "t3.large"
  key_name                    = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name = "jenkins"
  }

user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              curl -o /tmp/deploy.sh https://raw.githubusercontent.com/atulkamble/ec2-jenkins/main/deploy.sh
              chmod +x /tmp/deploy.sh
              bash /tmp/deploy.sh
              EOF
}
