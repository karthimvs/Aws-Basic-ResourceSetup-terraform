terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "vpc001" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MYVPC-001"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.vpc001.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "MYVPC-001-PUB-SUB"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.vpc001.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "MYVPC-001-PRI-SUB"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc001.id

  tags = {
    Name = "MYVPC-001-IGW"
  }
}

resource "aws_route_table" "pubrtr" {
  vpc_id = aws_vpc.vpc001.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "MYVPC-001-PUB-RTR"
  }
}

resource "aws_route_table_association" "pubrtrasso" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrtr.id
}

resource "aws_eip" "teip" {
  vpc      = true
}

resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.teip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "MY-VPC-NAT"
  }
}

resource "aws_route_table" "prirtr" {
  vpc_id = aws_vpc.vpc001.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }

  tags = {
    Name = "MYVPC-001-PRI-RTR"
  }
}

resource "aws_route_table_association" "prirtrasso" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirtr.id
}

resource "aws_security_group" "allow_all_teraform" {
  name        = "allow_all_teraform"
  description = "Allow All inbound traffic"
  vpc_id      = aws_vpc.vpc001.id

  ingress {
    description = "Http traffic from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH traffic from VPC"
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

  tags = {
    Name = "Allow Httpd and ssh SG Group"
  }
}

resource "aws_key_pair" "key-pair" {
  key_name   = "tera-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAkBwk3ACAkR2QjL0x8576l/dwUcIIn6n0t8fkRK/ocBQk/jVeAIwBghjWXbJGbF36ScYvbOSXA6/Tfl4Frg03S4cd+RS9UUI29Nml1zOWOvV7IFJJ1SLN27a8nP2zKsgiB+Rnu+aJXqXMQhIIMyr2+Y5Bmoi343TwXIo7BQ4iunIlUWoli0GpX8SZH2RchEjfY9hzOxM7YmVf15MbM2nMoABUp6VMXKrFVHvF9HnW7L+ge9NqttatoGlFow1bjxmWesxBdK2X6WhKQbTSl5k9UhVayNTaK12EYSRf4fNCZ+qWKUUQWS1ses+yRqfTNfp3AGsRCpiCmVea2ndxp2gTHw== rsa-key-20211024"
}

#Amazon Linux
resource "aws_instance" "instance1" {
  ami                              = "ami-041d6256ed0f2061c"
  associate_public_ip_address      = true
  subnet_id                        = aws_subnet.pubsub.id
  instance_type                    = "t2.micro"
  key_name                         = "tera-key"
  vpc_security_group_ids           = [aws_security_group.allow_all_teraform.id]
  user_data = "${file("user_data.sh")}"

  tags = {
    Name = "Terra form test Machine"
    Batch = "jenkins Master"
  }
}

#Amazon Linux
resource "aws_instance" "instance2" {
  ami                              = "ami-041d6256ed0f2061c"
  associate_public_ip_address      = true
  subnet_id                        = aws_subnet.prisub.id
  instance_type                    = "t2.micro"
  key_name                         = "tera-key"
  vpc_security_group_ids           = [aws_security_group.allow_all_teraform.id]

  tags = {
    Name = "Terra form test Machine"
    Batch = "Jenkins Node"
  }
}

#Redhat 8.4
resource "aws_instance" "instance3" {
 ami 				   = "ami-06a0b4e3b7eb7a300"
 associate_public_ip_address	   = true
 subnet_id 			   = aws_subnet.pubsub.id
 instance_type 			   = "t2.micro"
 key_name 			   = "tera-key"
 vpc_security_group_ids 	   = [aws_security_group.allow_all_teraform.id]
 
 tags = {
	Name = "Test 33"
	Batch = "Client-1"
 }
}
