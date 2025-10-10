#!/bin/bash

# Update system and install required packages
sudo yum update -y
sudo yum install -y git docker maven wget

# Git configuration
git --version
git config --global user.name "Atul Kamble"
git config --global user.email "atul_kamble@hotmail.com"
git config --list

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user and jenkins to docker group
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

# Install Amazon Corretto 21 (Java)
sudo dnf install java-21-amazon-corretto -y
java --version

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Print Jenkins and Maven versions
jenkins --version || echo "Jenkins installed"
mvn -v

# Fetch instance public IP from AWS instance metadata (if running on EC2) and print Jenkins URL
if command -v curl >/dev/null 2>&1; then
	# IMDSv2 token
	TOKEN=$(curl -s -m 5 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60") || TOKEN=""
	if [ -n "$TOKEN" ]; then
		PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
	else
		PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
	fi
	if [ -n "$PUBLIC_IP" ]; then
		echo "Jenkins UI: http://$PUBLIC_IP:8080"
	else
		echo "Jenkins UI: http://<public-ip>:8080  (public IP not found via instance metadata)"
	fi
else
	echo "curl not available; cannot query instance metadata for public IP. Jenkins UI: http://<instance-ip>:8080"
fi
