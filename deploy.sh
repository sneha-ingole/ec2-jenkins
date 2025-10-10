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

	# Install recommended Jenkins plugins (docker, docker-pipeline, Blue Ocean)
	# Uses jenkins-plugin-cli (bundled with recent Jenkins packages). Run as root so it can write to JENKINS_HOME.
	if command -v jenkins-plugin-cli >/dev/null 2>&1; then
		echo "Installing Jenkins plugins: docker-plugin, docker-workflow, blueocean"
		# retry a couple times in case network is flaky
		for attempt in 1 2 3; do
			if jenkins-plugin-cli --plugins docker-plugin docker-workflow blueocean; then
				echo "Plugins installed successfully"
				break
			else
				echo "Plugin install attempt $attempt failed, retrying in 5s..."
				sleep 5
			fi
		done
	else
		echo "jenkins-plugin-cli not found. Attempting to install plugins by placing .hpi files is unsupported in this script."
		echo "If plugins are required, install jenkins-plugin-cli or manually add plugins to /var/lib/jenkins/plugins and restart Jenkins."
	fi

	# Restart Jenkins to load new plugins and wait until the HTTP endpoint responds
	sudo systemctl restart jenkins
	echo "Waiting for Jenkins to become available on localhost:8080"
	for i in 1 30; do
		if command -v curl >/dev/null 2>&1 && curl -sSf http://127.0.0.1:8080 >/dev/null 2>&1; then
			echo "Jenkins is up"
			break
		fi
		echo "Waiting... ($i/30)"
		sleep 5
	done

	# Print initial admin password (if still present)
	if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
		echo "Jenkins Admin Password:"
		sudo cat /var/lib/jenkins/secrets/initialAdminPassword
	fi
