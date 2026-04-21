# Cria um repositório no Amazon ECR para armazenar as imagens Docker do site estático
resource "aws_ecr_repository" "site_estatico" {
  name = "infra-dev-site_estatico-ecr"

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Define uma política de ciclo de vida para o repositório do Amazon ECR, mantendo apenas as últimas 5 imagens
resource "aws_ecr_lifecycle_policy" "policy_site_estatico" {
  repository = aws_ecr_repository.site_estatico.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter últimas 5 imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}