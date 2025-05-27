ip="50.210.21.0/32"

aws ec2 describe-security-groups \
  --query "SecurityGroups[?IpPermissions[?IpRanges[?CidrIp=='$ip']]]" \
  --output table
