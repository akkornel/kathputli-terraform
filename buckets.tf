# vim: ts=2 sw=2 et


#
# S3 BUCKETS
#

# First, create the home S3 bucket that will store all of the configuration.
# TODO: We somehow need to set up conditional replication, if a remote region 
# was set.

resource "aws_s3_bucket" "puppet_config_home" {
  bucket = "${var.bucket_prefix}-config-home"
  region = "${var.home_region}"

  force_destroy = "true"

  acl = "private"

  versioning {
    enabled = true
  }

}

# Create a second S3 bucket, using our remote region, that can hold copies of 
# the Puppet configuration.

resource "aws_s3_bucket" "puppet_config_remote" {
  bucket   = "${var.bucket_prefix}-config-remote"
  provider = "aws.remote_provider"
  region   = "${var.remote_region}"
  count    = "${var.remote_region == "none" ? 0 : 1}"

  force_destroy = "true"

  acl      = "private"

  versioning {
    enabled = true
  }
}
