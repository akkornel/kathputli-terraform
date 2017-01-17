# vim: ts=2 sw=2 et

# 
# CLIENT-SET VARIABLES
#

variable "admin_email" {
  type        = "string"
  description = "The administrator's email addess"
}

variable "vpc_cidr" {
  type        = "string"
  description = "The IPv4 network to use for the VPC, in CIDR notation.  The network must be a /24 network, meaning the last octet will always be zero."
  default     = "10.1.0.0/24"
}

variable "home_region" {
  type        = "string"
  description = "The home region, where most of the work is done"
}

variable "remote_region" {
  type        = "string"
  description = "An optional second region for additional resiliency.  To disable, set to 'none'."
  default     = "none"
}

variable "domain" {
  type        = "string"
  description = "A domain to use for the Route53 zone, containing hostnames that your Puppet clients connect to."
}

variable "bucket_prefix" {
  type        = "string"
  description = "A prefix for the S3 bucket(s) created to hold configuration."
}

variable "ssh_key" {
  type        = "string"
  description = "The SSH public key to use for SSHing into EC2 instances."
}

variable "bootstrap_spot" {
  type        = "string"
  description = "Defaults to false.  Set to true to use a spot fleet to maintain the bootstrap server, instead of an auto-scaling group."
  default     = "false"
}

variable "bootstrap_spot_price" {
  type        = "string"
  description = "If bootstrap_spot is true, this is the maximum spot price.  This should be set to something less than the hourly price of an on-demand t2.small instance."
  default     = "0.02"
}

variable "bootstrap_spot_expiration" {
  type        = "string"
  description = "A date/time, in YYYY-MM-DDTHH:MM:SSZ format, marking the end point of the spot request.  This needs to be moved forward regularly."
  default     = "2018-01-04T00:00:00Z"
}

variable "gpg_key" {
  type        = "string"
  description = "The long key ID (that is, the last 16 hex characters) for the GPG key that we will use to verify the software we download.  The key must be present in (at least) the pgp.net key servers."
  default     = "A2BF8503E5E5AFC8"
}

variable "bootstrap_repo" {
  type        = "string"
  description = "The URL of the Git repository containing the bootstrap code.  This may be any valid URL, so long as authentication is NOT needed to clone."
  default     = "https://github.com/kathputli/bootstrap-aws.git"
}

variable "bootstrap_tag" {
  type        = "string"
  description = "The name of the tag to check out from bootstrap_repo.  This tag MUST be signed by the key specified in gpg_key."
  default     = "production"
}
