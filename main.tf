#provider

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

#Create vpc

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Dineshvpc"
  }
}

#public subnet

resource "aws_subnet" "mypub" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pubsub"
  }
}


#private subnet

resource "aws_subnet" "mypri" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "prisub"
  }
}


#internet  gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "Dineshigw"
  }
}


#route table for public

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "dineshpubrt"
  }
}

#route table association

resource "aws_route_table_association" "pubrtasso" {
  subnet_id      = aws_subnet.mypub.id
  route_table_id = aws_route_table.pubrt.id
}



#elactic ip for private route table

resource "aws_eip" "myeip" {
  domain = "vpc"
}


#nat gateway

resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.mypub.id

  tags = {
    Name = "My-VPC-NAT"
  }
}

#route table for Private

resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }

  tags = {
    Name = "dineshprirt"
  }
}

#route table association

resource "aws_route_table_association" "prirtasso" {
  subnet_id      = aws_subnet.mypri.id
  route_table_id = aws_route_table.prirt.id
}


#security group

resource "aws_security_group" "public-sg" {
  name        = "Public_security_group"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {

    description = "Tls for vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "Tls for vpc"
    from_port   = 80
    to_port     = 80
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
    Name = "allow_tls"
  }
}



#private security group

resource "aws_security_group" "pri_sg" {
  name        = "private_securitygroup"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {

    description     = "Tls for vpc"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.public-sg.id]
  }

  ingress {

    description     = "Tls for vpc"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.public-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "allow_tls"
  }
}




resource "aws_instance" "Dinesh_pub" {
  ami                         = "ami-053b12d3152c0cc71"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.mypub.id
  vpc_security_group_ids      = [aws_security_group.pub-sg.id]
  associate_public_ip_address = true


  tags = {
    Name = "Dinesh_pubec2"
  }
}

resource "aws_instance" "Dinesh_pri" {
  ami                    = "ami-053b12d3152c0cc71"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mypri.id
  vpc_security_group_ids = [aws_security_group.pri-sg.id]



  tags = {
    Name = "Dinesh_priec2"
  }
}
