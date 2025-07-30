output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_ec2.public_ip
}

output "ssh_connection_command" {
  description = "SSH command to connect to the Jenkins EC2 instance"
  value       = "ssh -i jenkins.pem ec2-user@${aws_instance.jenkins_ec2.public_ip}"
}
