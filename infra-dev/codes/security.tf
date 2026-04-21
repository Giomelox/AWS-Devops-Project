# ==========================================================
# Security Group para a instância EC2 
# Permite acesso HTTP (porta 80) de qualquer lugar, permitindo que o site estático seja acessível publicamente
# Permite todo o tráfego de saída, garantindo que a instância EC2 possa se comunicar com outros serviços da AWS, como o Amazon ECR para puxar as imagens Docker do site estático
# ==========================================================
resource "aws_security_group" "sg_ssh" {
  name   = "infra-dev-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir acesso HTTP de qualquer lugar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir todo o tráfego de saída
  }
}