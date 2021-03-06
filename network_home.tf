# vim: ts=2 sw=2 et


#
# VPC, GW, ROUTE TABLE
#

# Create our home VPC

resource "aws_vpc" "home" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "Puppet VPC"
  }
}

# Create a gateway for outside access

resource "aws_internet_gateway" "home" {
  vpc_id = "${aws_vpc.home.id}"

  tags {
    Name = "Puppet VPC Internet Link"
  }
}

# Create a routing table that allows traffic out

resource "aws_route_table" "home" {
  vpc_id = "${aws_vpc.home.id}"

  tags {
    Name = "Puppet VPC Route Table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.home.id}"
  }
}

#
# SUBNETS
#

# Create three private subnets for our Puppet masters.

resource "aws_subnet" "home_master1" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}a"
  
  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 0)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Master Subnet #1"
  }
}

resource "aws_route_table_association" "home_master1" {
  subnet_id      = "${aws_subnet.home_master1.id}"
  route_table_id = "${aws_route_table.home.id}"
}

resource "aws_subnet" "home_master2" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}b"
  
  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 1)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Master Subnet #2"
  }
}

resource "aws_route_table_association" "home_master2" {
  subnet_id      = "${aws_subnet.home_master2.id}"
  route_table_id = "${aws_route_table.home.id}"
}

resource "aws_subnet" "home_master3" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}c"
  
  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 2)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Master Subnet #3"
  }
}

resource "aws_route_table_association" "home_master3" {
  subnet_id      = "${aws_subnet.home_master3.id}"
  route_table_id = "${aws_route_table.home.id}"
}

# Create two subnets for misc. systems.

resource "aws_subnet" "home_misc1" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}a"

  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 3)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Misc. Subnet"
  }
}

resource "aws_route_table_association" "home_misc1" {
  subnet_id      = "${aws_subnet.home_misc1.id}"
  route_table_id = "${aws_route_table.home.id}"
}

resource "aws_subnet" "home_misc2" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}b"

  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 4)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Misc. Subnet"
  }
}

resource "aws_route_table_association" "home_misc2" {
  subnet_id      = "${aws_subnet.home_misc2.id}"
  route_table_id = "${aws_route_table.home.id}"
}

# Create two subnets for our CA.

resource "aws_subnet" "ca1" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}b"

  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 5)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "CA Subnet"
  }
}

resource "aws_route_table_association" "ca1" {
  subnet_id      = "${aws_subnet.ca1.id}"
  route_table_id = "${aws_route_table.home.id}"
}

resource "aws_subnet" "ca2" {
  vpc_id = "${aws_vpc.home.id}"
  availability_zone = "${var.home_region}c"

  cidr_block = "${cidrsubnet(var.vpc_cidr, 3, 6)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "CA Subnet"
  }
}

resource "aws_route_table_association" "ca2" {
  subnet_id      = "${aws_subnet.ca2.id}"
  route_table_id = "${aws_route_table.home.id}"
}

# BTW, there is one /27 left in this VPC!

#
# SECURITY GROUPS
#

resource "aws_security_group" "home_bastion" {
  name_prefix = "bastion_group"
  description = "Bastion host security group"
  vpc_id      = "${aws_vpc.home.id}"

  # Allow ping and SSH in from anywhere

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 22
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

resource "aws_security_group" "home_ca" {
  name_prefix = "ca_group"
  description = "Puppet CA security group"
  vpc_id      = "${aws_vpc.home.id}"

  # Allow ping and Puppet web from anywhere

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # Allow SSH from the bastion systems

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ "${aws_security_group.home_bastion.id}" ]
  }

  # Allow outgoing to anywhere

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_security_group" "home_nfs_bootstrap" {
  name_prefix = "puppet_nfs_bootstrap"
  description = "Allow NFS access to bootstrap data"
  vpc_id      = "${aws_vpc.home.id}"

  # Allow NFS access from the Bastion security group
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.home_bastion.id}"
    ]
  }
}

resource "aws_security_group" "home_nfs_ca" {
  name_prefix = "puppet_nfs_ca"
  description = "Allow NFS access to CA data"
  vpc_id      = "${aws_vpc.home.id}"

  # Allow NFS access from the CA and Bastion security groups
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.home_ca.id}",
      "${aws_security_group.home_bastion.id}"
    ]
  }
}

resource "aws_security_group" "home_puppet" {
  name_prefix = "puppet_group"
  description = "Puppet server security group"
  vpc_id      = "${aws_vpc.home.id}"

  # Allow ping and Puppet web from anywhere

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # Allow SSH from the bastion systems

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ "${aws_security_group.home_bastion.id}" ]
  }

  # Allow outgoing to anywhere

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}
