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