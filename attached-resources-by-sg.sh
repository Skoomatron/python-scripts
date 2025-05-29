#!/bin/bash

# Usage: ./find-sg-attachments-us.sh sg-xxxxxxxxxxxxxxxxx
# Purpose: Find EC2 instances and ENIs associated with a given SG in select U.S. regions.

sg_id="sg-083e97f2bac6ab2e9"

if [[ -z "$sg_id" ]]; then
  echo "❌ Please provide a security group ID (e.g., sg-0abc123def456ghij)"
  exit 1
fi

regions=(us-east-1 us-east-2 us-west-1 us-west-2)

echo "🔍 Searching U.S. regions for resources using Security Group: $sg_id"

for region in "${regions[@]}"; do
  echo ""
  echo "===================================================="
  echo "🌍 Region: $region"
  echo "===================================================="

  echo -e "\n📦 EC2 Instances:"
  aws ec2 describe-instances \
    --region "$region" \
    --filters Name=instance.group-id,Values="$sg_id" \
    --query "Reservations[].Instances[].{Instance:InstanceId,PrivateIP:PrivateIpAddress,State:State.Name}" \
    --output table || echo "❌ No EC2 instances found"


  echo -e "\n🔌 Network Interfaces (ENIs):"
  aws ec2 describe-network-interfaces \
    --region "$region" \
    --filters Name=group-id,Values="$sg_id" \
    --query "NetworkInterfaces[].[NetworkInterfaceId,PrivateIpAddress,Attachment.InstanceId,Description]" \
    --output table || echo "❌ No ENIs found"
done

echo ""
echo "✅ Search complete."
