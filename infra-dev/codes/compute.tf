# Cria uma instância EC2 usando a imagem do Amazon Linux 2, com a chave SSH criada e o security group para acesso SSH
resource "aws_instance" "site_estatico_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg_ssh.id]
  subnet_id              = aws_subnet.public_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true
  availability_zone           = aws_subnet.public_subnet.availability_zone

  user_data = <<-EOF
    #!/bin/bash

    # Atualiza pacotes
    yum update -y

    # Instala Docker
    yum install -y docker

    # Inicia Docker
    systemctl start docker
    systemctl enable docker

    # Login no ECR
    aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 538073092645.dkr.ecr.us-east-2.amazonaws.com

    # Baixa imagem
    docker pull 538073092645.dkr.ecr.us-east-2.amazonaws.com/site_estatico:v1.0

    # Roda container
    docker run -d -p 80:80 538073092645.dkr.ecr.us-east-2.amazonaws.com/site_estatico:v1.0

    EOF
}