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

# =========================
# SSM AGENT (ESSENCIAL PARA QUE EU CONSIGA ME CONECTAR NA INSTÂNCIA PELO AWS SYSTEM MANAGER)
# =========================
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent