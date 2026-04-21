output "ip_publico_ec2" {
  value = aws_instance.site_estatico_ec2.public_ip
}

output "id_ec2" {
  value = aws_instance.site_estatico_ec2.id
}

output "aws_ecr_repository_url" {
  value = aws_ecr_repository.site_estatico.repository_url
}