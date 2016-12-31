# vim: ts=2 sw=2 et


#
# ROUTE 53 DOMAINS
#

# We have a single domain, managed in Route53, which contains entries for each 
# group using the service, as well as each box created.

resource "aws_route53_zone" "puppet_zone" {
  name = "${var.domain}"
}
