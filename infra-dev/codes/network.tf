# Criação da VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Criação de uma sub-rede pública dentro da VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Criação de uma sub-rede privada dentro da VPC
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

# Criação de um gateway de internet para permitir acesso à internet a partir da sub-rede pública
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# --------------------------------------------------
# ROUTE TABLE PARA A SUB-REDE PÚBLICA
# --------------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
# --------------------------------------------------
# --------------------------------------------------

# Criação de um NAT Gateway para permitir que as instâncias na sub-rede privada acessem a internet, 
# mas sem permitir acesso direto a partir da internet
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Criação do NAT Gateway usando o Elastic IP criado e associando-o à sub-rede pública
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Criação de uma route table para a sub-rede privada, associando-a ao NAT Gateway para 
# permitir acesso à internet a partir da sub-rede privada
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

# Adiciona uma rota para a internet
resource "aws_route" "nat_gateway_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Associa a route table da sub-rede privada à sub-rede privada
resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}