# Cria um grupo de segurança para permitir acesso SSH às instâncias EC2
resource "aws_security_group" "sg_ssh" {
  name   = "allow_ssh"
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