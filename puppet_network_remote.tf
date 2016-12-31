# vim: ts=2 sw=2 et


#
# VPC, GW, ROUTE TABLE
#

# Create our remote VPC

resource "aws_vpc" "remote" {
  cidr_block = "10.1.0.0/24"
  provider   = "aws.remote_provider"
  count      = "${var.remote_region == "none" ? 0 : 1}"

  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "Remote Puppet VPC"
  }
}

# Create a gateway for outside access

resource "aws_internet_gateway" "remote" {
  vpc_id     = "${aws_vpc.remote.id}"
  provider   = "aws.remote_provider"
  count      = "${var.remote_region == "none" ? 0 : 1}"

  tags {
    Name = "Remote Puppet VPC Internet Link"
  }
}

# Create a routing table that allows traffic out

resource "aws_route_table" "remote" {
  vpc_id     = "${aws_vpc.remote.id}"
  provider   = "aws.remote_provider"
  count      = "${var.remote_region == "none" ? 0 : 1}"

  tags {
    Name = "Remote Puppet VPC Route Table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.remote.id}"
  }
}

#
# SUBNETS
#

# Create three private subnets for our Puppet masters.

resource "aws_subnet" "remote_master1" {
  provider       = "aws.remote_provider"
  count          = "${var.remote_region == "none" ? 0 : 1}"

  vpc_id            = "${aws_vpc.remote.id}"
  availability_zone = "${var.remote_region}a"
  
  cidr_block = "10.1.0.0/27"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Remote Master Subnet #1"
  }
}

resource "aws_route_table_association" "remote_master1" {
  provider       = "aws.remote_provider"
  count          = "${var.remote_region == "none" ? 0 : 1}"

  subnet_id      = "${aws_subnet.remote_master1.id}"
  route_table_id = "${aws_route_table.remote.id}"
}

resource "aws_subnet" "remote_master2" {
  provider          = "aws.remote_provider"
  count             = "${var.remote_region == "none" ? 0 : 1}"
  
  vpc_id            = "${aws_vpc.remote.id}"
  availability_zone = "${var.remote_region}b"

  cidr_block = "10.1.0.32/27"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Remote Master Subnet #2"
  }
}

resource "aws_route_table_association" "remote_master2" {
  provider       = "aws.remote_provider"
  count          = "${var.remote_region == "none" ? 0 : 1}"

  subnet_id      = "${aws_subnet.remote_master2.id}"
  route_table_id = "${aws_route_table.remote.id}"
}

resource "aws_subnet" "remote_master3" {
  provider          = "aws.remote_provider"
  count             = "${var.remote_region == "none" ? 0 : 1}"

  vpc_id            = "${aws_vpc.remote.id}"
  availability_zone = "${var.remote_region}c"
  
  cidr_block = "10.1.0.64/27"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Remote Master Subnet #3"
  }
}

resource "aws_route_table_association" "remote_master3" {
  provider       = "aws.remote_provider"
  count          = "${var.remote_region == "none" ? 0 : 1}"

  subnet_id      = "${aws_subnet.remote_master3.id}"
  route_table_id = "${aws_route_table.remote.id}"
}

# Create one subnet for misc. systems.

resource "aws_subnet" "remote_misc1" {
  vpc_id            = "${aws_vpc.remote.id}"
  provider          = "aws.remote_provider"
  availability_zone = "${var.remote_region}a"
  count             = "${var.remote_region == "none" ? 0 : 1}"

  cidr_block = "10.1.0.128/27"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Remote Misc. Subnet"
  }
}

resource "aws_route_table_association" "remote_misc1" {
  provider       = "aws.remote_provider"
  count          = "${var.remote_region == "none" ? 0 : 1}"

  subnet_id      = "${aws_subnet.remote_misc1.id}"
  route_table_id = "${aws_route_table.remote.id}"
}

#
# SECURITY GROUPS
#

resource "aws_security_group" "remote_bastion" {
  provider   = "aws.remote_provider"
  count      = "${var.remote_region == "none" ? 0 : 1}"

  name        = "bastion_group"
  description = "Remote Bastion host security group"
  vpc_id      = "${aws_vpc.remote.id}"

  # Allow ping and SSH in from anywhere

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # Allow outgoing to anywhere

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_security_group" "remote_puppet" {
  provider   = "aws.remote_provider"
  count      = "${var.remote_region == "none" ? 0 : 1}"

  name        = "puppet_group"
  description = "Remote Puppet server security group"
  vpc_id      = "${aws_vpc.remote.id}"

  # Allow ping and Puppet web from anywhere

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 0
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # Allow SSH from the bastion systems

  ingress {
    from_port       = 0
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ "${aws_security_group.remote_bastion.id}" ]
  }

  # Allow outgoing to anywhere

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}
