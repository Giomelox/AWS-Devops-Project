#!/bin/bash

# Atualiza pacotes
yum update -y

# Instala Docker
yum install -y docker

# Inicia Docker
systemctl start docker
systemctl enable docker

# libera uso do docker sem sudo
usermod -aG docker ec2-user