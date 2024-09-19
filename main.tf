resource "aws_vpc" "vpc" {
  cidr_block = "10.2.0.0/16"
  tags = {
    "Name" = "CodeBuid-Torsten"
  }
}


# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Test-EC2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  #availability_zone = "us-east-1a" # Change to your preferred availability zone

  tags = {
    Name = "public-subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 instance
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows SSH from anywhere (adjust as necessary)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP access
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTPS access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# EC2 Instance
resource "aws_instance" "linux_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (replace with the latest one for your region)
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.public.id
  security_groups        = [aws_security_group.ec2_sg.name]
  associate_public_ip_address = true  # To allow internet access

  key_name = "lab-key-pair"  # Replace with your key pair name

  tags = {
    Name = "linux-ec2-instance"
  }
}

# Elastic IP
resource "aws_eip" "ec2_eip" {
  vpc      = true
  instance = aws_instance.linux_instance.id
}