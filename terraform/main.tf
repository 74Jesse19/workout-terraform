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

# Create security group to allow http access
resource "aws_security_group" "http" {
  name = "http Access"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port   = 80
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
resource "aws_iam_role" "backend_dynamodb_access" {
  name = "backend-dynamodb-access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "backend_dynamodb_policy" {
  role       = aws_iam_role.backend_dynamodb_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_instance" "artifactory" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  key_name = "JW-SSH-KEY"
  associate_public_ip_address = true
  subnet_id                    = aws_subnet.public.id
  vpc_security_group_ids       = [aws_security_group.ssh.id,aws_security_group.http.id]

  tags = {
    Name = "Artifactory Server"
  }
}

resource "aws_instance" "backend" {
  ami           = "ami-0bb84b8ffd87024d8"
  instance_type = "t2.micro"
  key_name = "JW-SSH-KEY"
  associate_public_ip_address = true
  subnet_id                    = aws_subnet.public.id
  vpc_security_group_ids       = [aws_security_group.ssh.id, aws_security_group.http.id]

  tags = {
    Name = "Backend Server"
  }
}

resource "aws_instance" "frontend" {
  ami           = "ami-0bb84b8ffd87024d8"
  instance_type = "t2.micro"
  key_name = "JW-SSH-KEY"
  associate_public_ip_address = true
  subnet_id                    = aws_subnet.public.id
  vpc_security_group_ids       = [aws_security_group.ssh.id]

  tags = {
    Name = "Frontend Server"
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
output "artifactory_public_ip" {
  value = aws_instance.artifactory.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}
