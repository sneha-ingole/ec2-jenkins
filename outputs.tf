output "jenkins_public_ip" {
  description = "EC2 Public IP"
  value       = aws_instance.jenkins.public_ip
}

output "ssh_connection_command" {
  description = "SSH into EC2"
  value       = "ssh -i jenkins.pem ec2-user@${aws_instance.jenkins.public_ip}"
}
