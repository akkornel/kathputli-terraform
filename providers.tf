# vim: ts=2 sw=2 et

#
# PROVIDERS
#

# First, configure the default aws provider to use our chosen home region.

provider "aws" {
  region = "${var.home_region}"
}

# Next, make a second aws provider to cover our remote region.
# Terraform validates this, so if we're not using a remote region, then we need 
# to set this to some valid value.

provider "aws" {
  alias  = "remote_provider"
  region = "${var.remote_region == "none" ? "us-east-1" : var.remote_region }"
}
