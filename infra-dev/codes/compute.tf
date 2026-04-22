# Cria uma instância EC2 usando a imagem do Amazon Linux 2, com a chave SSH criada e o security group para acesso SSH
resource "aws_instance" "site_estatico_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg_ssh.id]
  subnet_id              = aws_subnet.public_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true
  availability_zone           = aws_subnet.public_subnet.availability_zone

  tags = {
    Name = "infra-dev-site-estatico-ec2"
  }

  user_data = file("user_data/ec2_user_data.sh")
}