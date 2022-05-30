
data "aws_availability_zones" "available_azs" {
    state = "available"
}

resource "aws_vpc" "vpc_dev" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.vpc_dev.id
  tags = {
    Name = "${var.env}-igw"
  }
}

#--------------Public subnets and routing----------------

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.vpc_dev.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_azs.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Public-${data.aws_availability_zones.available_azs.names[count.index]}-subnet"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc_dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "public-rt-${var.env}"
  }
}

resource "aws_route_table_association" "public_ass" {
  count = length(aws_subnet.public_subnets[*].id)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public-rt.id
}

#--------------EIP and NAT Gateway----------------

resource "aws_eip" "nat_eip" {
  count = length(var.private_subnet_cidrs)
  vpc = true
  tags = {
      Name = "${var.env}-nat-gw-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
  tags = {
    Name = "${var.env}-nat-gw-${count.index + 1}"
  }
}

#--------------Private subnets and routing----------------

resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.vpc_dev.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_azs.names[count.index]
  
  tags = {
    Name = "Private-${data.aws_availability_zones.available_azs.names[count.index]}-subnet"
  }
}

resource "aws_route_table" "private-rt" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.vpc_dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "private-rt-${var.env}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_ass" {
  count = length(aws_subnet.private_subnets[*].id)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private-rt[count.index].id
}

#----------------------------------------------------------------