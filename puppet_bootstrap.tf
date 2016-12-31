# vim: ts=2 sw=2 et

# Create a role for the bootstrap system, and link the role to the policy.

resource "aws_iam_role" "bootstrap" {
  name = "Bootstrap"
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

# Attach a policy to the role, allowing everything.

resource "aws_iam_role_policy" "bootstrap" {
  name = "Bootstrap"
  role = "${aws_iam_role.bootstrap.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Create an instance profile containing our role, so that it can be attached to 
# EC2 instances.

resource "aws_iam_instance_profile" "bootstrap" {
  name = "Bootstrap"
  roles = [
    "${aws_iam_role.bootstrap.name}"
  ]
}

# Create a bootstrap configuration.
# This config defines an Ubuntu Xenial system, to which we fetch, verify, and 
# run a script that performs the remaining bootstrap tasks.

resource "aws_launch_configuration" "bootstrap" {
  name              = "Bootstrap"
  instance_type     = "t2.small"
  placement_tenancy = "default"
  image_id          = "${var.bootstrap_ami[var.home_region]}"
  enable_monitoring = "false"

  key_name                    = "${aws_key_pair.admin_home.id}"
  associate_public_ip_address = "true"
  security_groups             = [ "${aws_security_group.home_bastion.id}" ]
  iam_instance_profile        = "${aws_iam_instance_profile.bootstrap.arn}"

  root_block_device = {
    volume_type           = "standard"
    volume_size           = "10"
    delete_on_termination = "true"
  }

  user_data = <<EOF
#!/bin/bash

# Uppgrade existing packages, and install Git & GPG
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y git gnupg gnupg-curl

# Fetch the bootstrap signing key
sudo -u ubuntu gpg --keyserver keys.gnupg.net --recv-keys FC411D5BA332BE922D2CE7F1A2BF8503E5E5AFC8
echo 'trusted-key A2BF8503E5E5AFC8' >> ~/.gnupg/gpg.conf
sudo -u ubuntu gpg --update-trustdb

# Fetch, verify, and run the bootstrap
cd ~ubuntu
sudo -u ubuntu git clone https://github.com/akkornel/kathputli-bootstrap.git
cd kathputli-bootstrap
sudo -u ubuntu git tag -v production >> /tmp/bootstrap_tag.txt || exit 1
sudo -u ubuntu git checkout production
exec ~ubuntu/kathputli-bootstrap/bootstrap.sh
EOF
}

# Create an auto-scaling group to maintain one bootstrap server

resource "aws_autoscaling_group" "Bootstrap" {
  name         = "Bootstrap"
  min_size     = "1"
  max_size     = "1"
  force_delete = "true"

  launch_configuration = "${aws_launch_configuration.bootstrap.id}"
  vpc_zone_identifier  = [ "${aws_subnet.home_misc1.id}" ]

  health_check_type         = "EC2"
  health_check_grace_period = "300"

  tag = [
    {
      key                 = "Type"
      value               = "Bootstrap"
      propagate_at_launch = "true"
    },
    {
      key                 = "NFS"
      value               = "${aws_efs_file_system.bootstrap.id}"
      propagate_at_launch = "true"
    },
  ]
}
