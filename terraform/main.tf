# Configure AWS provider
provider "aws" {
  region = "us-east-1" 
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Workout VPC"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" 

  tags = {
    Name = "Public Subnet"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public Route Table"
  }
}

# Create route to internet gateway
resource "aws_route" "public_route" {
  route_table_id  = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id      = aws_internet_gateway.gateway.id
}

# Associate public subnet with route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id  = aws_route_table.public.id
}

# Create security group to allow SSH access
resource "aws_security_group" "ssh" {
  name = "SSH Access"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch 2 EC2 Instances
resource "aws_instance" "webserver" {
  count         = 2
  ami           = "ami-0bb84b8ffd87024d8" 
  instance_type = "t2.micro"
  associate_public_ip_address = true

  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "Web Server ${count.index}"
  }
}

# Create DynamoDB table named workouts and add
resource "aws_dynamodb_table" "workouts" {
  name = "workouts"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

 #throughput settings
  read_capacity = 5
  write_capacity = 5
}

# Output public IP addresses of the instances
output "public_ip" {
  value = aws_instance.webserver[*].public_ip
}
