provider "aws" {
  region = "us-east-1"
}

# Generate SSH key pair
resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  content              = tls_private_key.jenkins.private_key_pem
  filename             = "${path.module}/jenkins.pem"
  file_permission      = "0400"
  directory_permission = "0700"
}

# Create AWS key pair
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins"
  public_key = tls_private_key.jenkins.public_key_openssh
}

# Security Group for EC2
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins"
  description = "Allow SSH, HTTP, HTTPS, Jenkins"

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
    description = "Jenkins"
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

# EC2 instance with remote-exec
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

  provisioner "remote-exec" {
    inline = [
      "sudo yum clean all",
      "sudo yum update -y",
      "sudo yum install -y git docker maven wget dnf",
      "git config --global user.name \"Atul Kamble\"",
      "git config --global user.email \"atul_kamble@hotmail.com\"",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user",
      "sudo dnf install java-21-amazon-corretto -y",
      "wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade -y",
      "sudo yum install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.jenkins.private_key_pem
      host        = self.public_ip
    }
  }

  # Wait until SSH is ready
  provisioner "file" {
    content     = "Jenkins setup complete"
    destination = "/tmp/jenkins_status.txt"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.jenkins.private_key_pem
      host        = self.public_ip
    }
  }
}
