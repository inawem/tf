provider "aws" {
	region = "us-east-1"
}

variable vpc_cidr_block {}
variable env_prefix {}
variable subnet_cidr_block {}
variable avail_zone {}
variable my_ip {}

resource "aws_vpc" "myapp-vpc" {
	cidr_block = var.vpc_cidr_block
	tags = {
			Name: "${var.env_prefix}-vpc"}
}

resource "aws_subnet" "myapp-subnet-1" { 
	vpc_id = aws_vpc.myapp-vpc.id
	cidr_block = var.subnet_cidr_block 
	availability_zone = var.avail_zone
	tags = {
	Name: "${var.env_prefix}-subnet-1"
	}
}

resource "aws_route_table" "myapp-route-table" {
vpc_id =  aws_vpc.myapp-vpc.id 
route {
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.myapp-igw.id
}
tags = {
	Name: "${var.env_prefix}-rtb"
}
}
  
resource "aws_internet_gateway" "myapp-igw" {
	vpc_id = aws_vpc.myapp-vpc.id
	tags = {
	Name: "${var.env_prefix}-igw"
	}
}

resource "aws_route_table_association" "a-rtb-subnet" {
subnet_id = aws_subnet.myapp-subnet-1.id
route_table_id = aws_route_table.myapp-route-table.id
}

# add default if you want to use default e.g. aws_default_...
resource "aws_security_group" "myapp-sg" {
	name = "myapp-sg"
	vpc_id = aws_vpc.myapp-vpc.id
	ingress { 
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [var.my_ip]
	}
ingress { 
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"] 
}

tags = {
	Name: "${var.env_prefix}-sg"
	}
}

data "aws_ami" "latest-amazon-linux-image" {
	most_recent = true
	owners = ["amazon"]
	filter  { 
		name = "name"
		values = ["amzn2-ami-hvm*"]
	}
	filter  { 
		name = "virtualization-type"
		values = ["hvm"]
	}
	 
}

resource "aws_instance" "myapp-server" {
	ami = data.aws_ami.latest-amazon-linux-image.id
	instance_type ="t2.micro" 
	# you can change it based on he machine
	subnet_id = aws_subnet.myapp-subnet-1.id
	vpc_security_group_ids = [aws_security_group.myapp-sg.id]
	availability_zone = var.avail_zone
	associate_public_ip_address = true
	user_data = <<EOF
				#!/bin/bash
				sudo yum update -y && sudo you install -y httpd.x86_64
				sudo systemctl start httpd.service 
				sudo  enable httpd.service 
				echo "Hello World from Dheeraj $(hostname —f)" > /var/WM/html/index. html 
			EOF
			
	key_name = "terraformkp"
	tags = {
		Name = "${var.env_prefix}-server"
	}
}
