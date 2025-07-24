#!/bin/bash

set -e

echo "🔄 Updating packages..."
sudo yum update -y

echo "📦 Installing Git..."
sudo yum install git -y
git --version

echo "🔧 Configuring Git..."
git config --global user.name "Atul Kamble"
git config --global user.email "atul_kamble@hotmail.com"
git config --list

echo "🐳 Installing Docker..."
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

echo "☕ Installing Java (Amazon Corretto 21)..."
sudo dnf install java-21-amazon-corretto -y
java --version

echo "📦 Installing Maven..."
sudo yum install maven -y
mvn -v

echo "🔧 Setting up Jenkins repo..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

echo "⬆️ Upgrading system and installing Jenkins..."
sudo yum upgrade -y
sudo yum install jenkins -y
jenkins --version

echo "👤 Adding Jenkins user to Docker group..."
sudo usermod -aG docker jenkins

echo "▶️ Starting and enabling Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "✅ Jenkins setup completed!"
echo "🌐 Access Jenkins via: http://<YOUR_EC2_PUBLIC_IP>:8080"
echo "🔐 Get your Jenkins initial password using:"
echo "    sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
