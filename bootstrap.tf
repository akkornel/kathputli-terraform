# vim: ts=2 sw=2 et

# This file contains the stuff to create the bootstrap instance.
# The bootstrap instance is the system which does some of the more-compilcated 
# systems setup, and which handles many of the priviledged operations.

# Create an IAM Role, which allows an EC2 instance to assume the role, and its 
# attached/embedded policies.
resource "aws_iam_role" "bootstrap" {
  name_prefix        = "Bootstrap"
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
  name_prefix = "Bootstrap"
  role        = "${aws_iam_role.bootstrap.id}"
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

  user_data = "${vars.bootstrap_user_data}"
}

# Create an auto-scaling group to maintain one bootstrap server
resource "aws_autoscaling_group" "bootstrap" {
  min_size         = "1"
  desired_capacity = "1"
  max_size         = "1"
  force_delete     = "true"

  launch_configuration = "${aws_launch_configuration.bootstrap.id}"
  vpc_zone_identifier  = [
    "${aws_subnet.home_misc1.id}",
    "${aws_subnet.home_misc2.id}",
  ]

  health_check_type         = "EC2"
  health_check_grace_period = "300"

  tag = [
    {
      key                 = "Type"
      value               = "Bootstrap"
      propagate_at_launch = "true"
    },
  ]
}
