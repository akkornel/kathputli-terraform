# vim: ts=2 sw=2 et

# This defines a key pair that the admin can use to SSH in.

resource "aws_key_pair" "admin_home" {
  public_key = "${var.ssh_key}"
}

resource "aws_key_pair" "admin_remote" {
  provider   = "aws.remote_provider"
  public_key = "${var.ssh_key}"
}
