ip="172.31.58.249"

aws ec2 describe-security-groups \
  --query "SecurityGroups[?IpPermissions[?IpRanges[?CidrIp=='$ip']]]" \
  --output table
