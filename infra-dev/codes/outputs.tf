output "ip_publico_ec2" {
  value = "IP público da EC2: ${aws_instance.site_estatico_ec2.public_ip}"
}

output "id_ec2" {
  value = "EC2 criada com ID: ${aws_instance.site_estatico_ec2.id}"
}

output "aws_ecr_repository_url" {
  value = "URL do repositório ECR: ${aws_ecr_repository.site_estatico.repository_url}"
}