# vim: ts=2 sw=2 et

# The Terraform file only defines one variable: bootstrap_ami

# This variable is a map, where the keys are AWS region IDs (preferably all of 
# them) and the values are is an AMI in each region.

# This is used to specify the "bootstrap AMI", the AMI that is used to create 
# the "bootstrap instance".  The "bootstrap instance" is the one and only 
# instance created by Terraform; it is used to provide a place for you to run 
# Terraform regularly (instead of just on your local system), and is also where 
# Packer is run (to build the Puppet CA and Puppet master images).

# Here is how to update this file:

# 1: Go to the Ubuntu Amazon EC2 Image Locator (it should be at
# https://cloud-images.ubuntu.com/locator/ec2/).
# 2: Enter "xenial" in the search box.  That will limit the list to only Xenial 
# images.
# 3: Click on the "Instance Type" column.  The output should now be sorted by 
# Instance Type, with "ebs-ssd" at the top.
# 4: Scroll down to the "hvm:ebs-ssd" Instance Type.  Copy the AMI IDs to the 
# mapping below.  If a new region appears, add it.

variable "bootstrap_ami" {
  type        = "map"
  description = "A mapping, converting AWS region names to bootstrap AMIs."
  default     = {
    ap-northeast-1 = "ami-18afc47f"
    ap-northeast-2 = "ami-93d600fd"
    ap-south-1     = "ami-dd3442b2"
    ap-southeast-1 = "ami-87b917e4"
    ap-southeast-2 = "ami-e6b58e85"
    ca-central-1   = "ami-7112a015"
    eu-central-1   = "ami-fe408091"
    eu-west-1      = "ami-ca80a0b9"
    eu-west-2      = "ami-ede2e889"
    sa-east-1      = "ami-e075ed8c"
    us-east-1      = "ami-9dcfdb8a"
    us-east-2      = "ami-fcc19b99"
    us-gov-west-1  = "ami-19d56d78"
    us-west-1      = "ami-b05203d0"
    us-west-2      = "ami-b2d463d2"
  }
}
