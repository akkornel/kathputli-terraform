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
