terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.00"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-vijaya"
    key            = "vote-app/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks-vijaya"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ironhack-proj1-vpc-vijaya"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public-vijaya" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private-vijaya" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
}

resource "aws_route_table" "public-igw-vijaya" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public-vijaya.id
  route_table_id = aws_route_table.public-igw-vijaya.id
}


resource "aws_eip" "nat_eip_vijaya" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-vijaya"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip_vijaya.id
  subnet_id     = aws_subnet.public-vijaya.id

  tags = {
    Name = "main-nat-vijaya"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private-nat-vijaya" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-nat-vijaya"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private-vijaya.id
  route_table_id = aws_route_table.private-nat-vijaya.id
}

resource "aws_security_group" "vote_result_sg" {
  name   = "vote-result-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis_worker_sg" {
  name   = "redis-worker-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "postgres_sg" {
  name   = "postgres-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.redis_worker_sg.id, aws_security_group.vote_result_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "ironhack-proj1-vote-result-vijaya" {
  ami                    = var.ami_id
  subnet_id              = aws_subnet.public-vijaya.id
  vpc_security_group_ids = [aws_security_group.vote_result_sg.id]
  instance_type          = var.instance_type
  key_name               = "docker-compose-lab-key-vijaya"

  tags = {
    Name = "ironhack-proj1-vote-result-vijaya"
  }
}

resource "aws_instance" "ironhack-proj1-redis-worker-vijaya" {
  ami                    = var.ami_id
  subnet_id              = aws_subnet.private-vijaya.id
  vpc_security_group_ids = [aws_security_group.redis_worker_sg.id]
  instance_type          = var.instance_type
  key_name               = "docker-compose-lab-key-vijaya"

  tags = {
    Name = "ironhack-proj1-redis-worker-vijaya"
  }
}

resource "aws_instance" "ironhack-proj1-postgres-db-vijaya" {
  ami                    = var.ami_id
  subnet_id              = aws_subnet.private-vijaya.id
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  instance_type          = var.instance_type
  key_name               = "docker-compose-lab-key-vijaya"

  tags = {
    Name = "ironhack-proj1-postgres-db-vijaya"
  }
}


