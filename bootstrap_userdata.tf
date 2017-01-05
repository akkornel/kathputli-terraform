# vim: ts=2 sw=2 et

# This file contains the user-data script that gets run on newly-created 
# bootstrap systems.  It has been moved to a separate file to keep things 
# looking cleaner.  It also makes modifications much easier to notice!

variable "bootstrap_userdata" {
  type = "string"
  description = "This is the user-data sent to newly-created bootstrap systems."
  default     = <<ENDUSERDATA
#!/bin/bash

# Create files with info on our config
cat - <<EOF > /etc/kathputli-bootstrap.json
{
  "admin_email": "${var.admin_email}",
  "home_bucket": "${aws_s3_bucket.puppet_config_home.bucket}",
  "remote_bucket": "${var.remote_region == "none" ?  "none" : "${var.bucket_prefix}-config-remote"}",
  "dns_zone": {
    "id": "${aws_route53_zone.puppet_zone.id}",
    "name": "${vars.domain}",
  },
  "efs_id": "${aws_efs_file_system.bootstrap.id}"
}
EOF
cat - <<EOF > /etc/kathputli-bootstrap.sh
ADMIN_EMAIL="${var.admin_email}"
HOME_BUCKET="${aws_s3_bucket.puppet_config_home.bucket}"
REMOTE_BUCKET="${var.remote_region == "none" ?  "none" : "${var.bucket_prefix}-config-remote"}"
DNS_ZONE_ID="${aws_route53_zone.puppet_zone.id}"
DNS_ZONE_NAME="${vars.domain}"
EFS_ID="${aws_efs_file_system.bootstrap.id}"
EOF

# Uppgrade existing packages, and install Git & GPG
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y git gnupg gnupg-curl

# Fetch the bootstrap signing key
sudo -u ubuntu gpg --keyserver keys.gnupg.net --recv-keys FC411D5BA332BE922D2CE7F1A2BF8503E5E5AFC8
echo 'trusted-key A2BF8503E5E5AFC8' >> ~/.gnupg/gpg.conf
sudo -u ubuntu gpg --update-trustdb

# Fetch, verify, and run the bootstrap
cd ~ubuntu
sudo -u ubuntu git clone https://github.com/akkornel/kathputli-bootstrap.git
cd kathputli-bootstrap
sudo -u ubuntu git tag -v production >> /tmp/bootstrap_tag.txt || exit 1
sudo -u ubuntu git checkout production
exec ~ubuntu/kathputli-bootstrap/bootstrap.sh
ENDUSERDATA
}
