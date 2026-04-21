# ==========================================================
# Criação de uma função IAM para permitir que as instâncias EC2 acessem o AWS Systems Manager (SSM),
# permitindo que sejam gerenciadas remotamente usando o SSM Session Manager, sem a necessidade de acesso SSH direto
# Cria uma função IAM para permitir que as instâncias EC2 acessem o repositório do Amazon ECR, permitindo que elas possam puxar as imagens Docker do site estático armazenadas no Amazon ECR
# ==========================================================

resource "aws_iam_role" "ec2_role" {
  name = "infra-dev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Anexa a política gerenciada do AWS para acesso de leitura ao Amazon ECR à função IAM criada para as instâncias EC2
resource "aws_iam_role_policy_attachment" "ec2_access_ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Anexa a política gerenciada do AWS para acesso ao AWS Systems Manager (SSM) à função IAM criada para as instâncias EC2, permitindo que elas sejam gerenciadas remotamente usando o SSM Session Manager
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "infra-dev-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================================================
# ==========================================================