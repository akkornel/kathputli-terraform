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
  name        = "Bootstrap"
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

# Next up comes auto-scaling configuration.
# This is the safest, and the default, way of maintaining your bootstrap server:
# An auto-scaling group is used to keep one bootstrap server running.
# There are two possible subnets, each in a different AZ, so that if something
# knocks out an entire AZ, a bootstrap server can be spun up in another AZ.

# Create a bootstrap configuration.
# This config defines an Ubuntu Xenial system, to which we fetch, verify, and 
# run a script that performs the remaining bootstrap tasks.
resource "aws_launch_configuration" "bootstrap" {
  name_prefix       = "Bootstrap"
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

  user_data = "${data.template_file.bootstrap_user_data.rendered}"
}

# Create an auto-scaling group to maintain one bootstrap server
resource "aws_autoscaling_group" "bootstrap" {
  min_size         = "${var.bootstrap_spot == "false" ? 1 : 0}"
  desired_capacity = "${var.bootstrap_spot == "false" ? 1 : 0}"
  max_size         = "${var.bootstrap_spot == "false" ? 1 : 0}"
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

  depends_on = [
    "aws_efs_mount_target.bootstrap1",
    "aws_efs_mount_target.bootstrap2"
  ]
}

#
#
#

# Create a role for the Spot Fleet service to assume.
resource "aws_iam_role" "bootstrap_fleet" {
  name_prefix        = "BootstrapFleet"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# As part of the role, allow the Spoot Fleet service to have access according
# to EC2's standard spot fleet policy.
resource "aws_iam_role_policy_attachment" "bootstrap_fleet" {
  role       = "${aws_iam_role.bootstrap_fleet.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole"
}

# Create a Spot fleet to maintain one bootstrap server
resource "aws_spot_fleet_request" "bootstrap" {
  count = "${var.bootstrap_spot == "true" ? 1 : 0}"

  iam_fleet_role = "${aws_iam_role.bootstrap_fleet.arn}"

  target_capacity = 1
  spot_price      = "${var.bootstrap_spot_price}"
  valid_until     = "${var.bootstrap_spot_expiration}"

# Once fixed, will later need to add m3.large,r3.large,r4.large,c3.large
# Also subnet ${aws_subnet.home_misc2.id}
  launch_specification {
    instance_type     = "m3.medium"
    ami               = "${var.bootstrap_ami[var.home_region]}"
    monitoring        = "false"

    key_name                    = "${aws_key_pair.admin_home.id}"
#    associate_public_ip_address = "true"
    vpc_security_group_ids      = [ "${aws_security_group.home_bastion.id}" ]
    iam_instance_profile        = "${aws_iam_instance_profile.bootstrap.name}"

    root_block_device {
      volume_type           = "standard"
      volume_size           = "10"
      delete_on_termination = "true"
    }

    availability_zone = "${aws_subnet.home_misc1.availability_zone}"
    subnet_id         = "${aws_subnet.home_misc1.id}"

    user_data = "${data.template_file.bootstrap_user_data.rendered}"
  }

  depends_on = [
    "aws_efs_mount_target.bootstrap1",
    "aws_efs_mount_target.bootstrap2"
  ]
}
