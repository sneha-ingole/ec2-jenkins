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
