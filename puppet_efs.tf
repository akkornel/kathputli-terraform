# vim: ts=2 sw=2 et

#
# CA STORAGE
#

# Create an EFS file system for CA storage

resource "aws_efs_file_system" "ca" {
  tags {
    Name = "CA Data"
    Type = "CA"
  }
}

# Allow the file system to be mounted by the CA subnets

resource "aws_efs_mount_target" "ca1" {
  file_system_id = "${aws_efs_file_system.ca.id}"
  subnet_id      = "${aws_subnet.ca1.id}"
  security_groups = [ "${aws_security_group.home_nfs_ca.id}" ]
}

#
# BOOTSTRAP STORAGE
#

resource "aws_efs_file_system" "bootstrap" {
  tags {
    Name = "Bootstrap Server Data"
    Type = "Bootstrap"
  }
}

resource "aws_efs_mount_target" "bootstrap" {
  file_system_id = "${aws_efs_file_system.bootstrap.id}"
  subnet_id      = "${aws_subnet.home_misc1.id}"
  security_groups = [ "${aws_security_group.home_nfs_bootstrap.id}" ]
}
