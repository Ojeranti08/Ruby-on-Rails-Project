# Resource Block
# Resource-1: Create VPC
resource "aws_vpc" "raildocker-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    "Name" = "Rail-Docker vpc"
  }
}

# Resource-2: Create Public Subnet
resource "aws_subnet" "raildocker-public-subnet" {
  vpc_id                  = aws_vpc.raildocker-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Rail-Docker public subnet"
  }
}

# Resource-3: Create Private Subnet
resource "aws_subnet" "raildocker-private-subnet" {
  vpc_id                  = aws_vpc.raildocker-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b" # Change the availability zone if necessary
  map_public_ip_on_launch = false
  tags = {
    Name = "Rail-Docker private subnet"
  }
}

# Resource-4: Create Internet Gateway
resource "aws_internet_gateway" "raildocker-igw" {
  vpc_id = aws_vpc.raildocker-vpc.id
  tags = {
    Name = "Rail-Docker igw"
  }
}

# Resource 5: Create Public Route Table
resource "aws_route_table" "raildocker-public-route-table" {
  vpc_id = aws_vpc.raildocker-vpc.id
  tags = {
    Name = "Rail-Docker public route table"
  }
}

# Resource-6: Create Private Route Table
resource "aws_route_table" "raildocker-private-route-table" {
  vpc_id = aws_vpc.raildocker-vpc.id
  tags = {
    Name = "Rail-Docker private route table"
  }
}

# Resource-7: Create Route in Route Table for Internet Access
resource "aws_route" "raildocker-public-route" {
  route_table_id         = aws_route_table.raildocker-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.raildocker-igw.id
}

# Resource-8: Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "raildocker-public-route-table-associate" {
  route_table_id = aws_route_table.raildocker-public-route-table.id
  subnet_id      = aws_subnet.raildocker-public-subnet.id
}

# Resource-9: Associate the Route Table with the Private Subnet
resource "aws_route_table_association" "raildocker-private-route-table-associate" {
  route_table_id = aws_route_table.raildocker-private-route-table.id
  subnet_id      = aws_subnet.raildocker-private-subnet.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "Rail-Docker-eip_NAT"
  }
}

# Resource-10: Create NAT Gateway
resource "aws_nat_gateway" "pub-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.raildocker-public-subnet.id
  tags = {
    Name = "Rail-Docker-gw NAT"
  }
}

# Resource-11: Create Security Group
resource "aws_security_group" "raildocker-sg" {
  name        = "RUBY, SSH & POSTGRESQL"
  description = "Allow RUBY, SSH & POSTGRESQL inbound traffic"
  vpc_id      = aws_vpc.raildocker-vpc.id

  ingress {
    description = "Allow SSH from port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Ruby from port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Postgresql from port 5432"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Rail-Docker-SG"
  }
}

# Resource-12: Create Route in Private Route Table for NAT Gateway
resource "aws_route" "raildocker-private-nat-route" {
  route_table_id         = aws_route_table.raildocker-private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.pub-nat.id # Use NAT Gateway
}
