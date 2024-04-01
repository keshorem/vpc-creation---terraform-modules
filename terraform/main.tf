resource "tls_private_key" "instance_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generate_key_pair" {
  key_name   = "instance_key"
  public_key = tls_private_key.instance_key.public_key_openssh
  depends_on = [
    tls_private_key.instance_key
  ]
}

resource "local_file" "generate_pem_file" {
  content         = tls_private_key.instance_key.private_key_pem
  filename        = "my-key-value-pair.pem"
  file_permission = "0400"
  depends_on = [
    tls_private_key.instance_key
  ]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" 
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Terraform VPC"
  }
}

resource "aws_security_group" "ssh-server-connect" {
  name        = "ssh-server-connect"
  description = "Allow HTTPS to web server"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH ingress"
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

resource "aws_subnet" "subnet_instance" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
}

data "aws_subnet" "selected_subnet" {
  id = aws_subnet.subnet_instance.id
}


resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_nat_gateway" "nat_gateway"{
    allocation_id = aws_eip.eip_nat.id
    subnet_id = aws_subnet.subnet_instance.id
    depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "eip_nat" {
    domain = "vpc"
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

}

resource "aws_route_table_association" "subnet_gathering" {
    subnet_id = aws_subnet.subnet_instance.id
    route_table_id = aws_route_table.route_table.id
}

resource "aws_instance" "my_instance" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ssh-server-connect.id]
  subnet_id     = data.aws_subnet.selected_subnet.id
  key_name = aws_key_pair.generate_key_pair.key_name
  associate_public_ip_address = true
  iam_instance_profile = "ec2_instance_profile"
  tags = {
    Name = "Terraform VPC creation"
    Owner = "DemoUser"
  }
}

