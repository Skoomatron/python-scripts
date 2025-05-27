#!/bin/bash

# ------------------------------------------------------------------
# Script: search-ip-all-aws.sh
# Purpose: Search AWS resources associated with a given IP (private or public)
# Author: Trevor Edwards (GCK)
# ------------------------------------------------------------------

ip="172.31.58.249"
regions=(us-west-1 us-west-2 us-east-1 us-east-2)

for region in "${regions[@]}"; do
  echo "===================================================="
  echo "🔍 Searching for IP: $ip in region: $region"
  echo "===================================================="

  echo -e "\n📦 EC2 Instances (private IP match):"
  result=$(aws ec2 describe-instances \
    --filters Name=private-ip-address,Values=$ip \
    --region $region \
    --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No EC2 instances found with private IP"

  echo -e "\n📦 EC2 Instances (public IP match):"
  result=$(aws ec2 describe-instances \
    --region $region \
    --query "Reservations[].Instances[?PublicIpAddress=='$ip'].[InstanceId,PublicIpAddress,Tags]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No EC2 instances found with public IP"

  echo -e "\n🔌 ENIs (private IP match):"
  result=$(aws ec2 describe-network-interfaces \
    --filters Name=private-ip-address,Values=$ip \
    --region $region \
    --query "NetworkInterfaces[*].[NetworkInterfaceId,PrivateIpAddress,Description,Attachment.InstanceId]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No ENIs found with private IP"

  echo -e "\n🔌 ENIs (public IP match):"
  result=$(aws ec2 describe-network-interfaces \
    --filters Name=association.public-ip,Values=$ip \
    --region $region \
    --query "NetworkInterfaces[*].[NetworkInterfaceId,Description,Attachment.InstanceId]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No ENIs found with public IP"

  echo -e "\n📌 Elastic IPs:"
  result=$(aws ec2 describe-addresses \
    --region $region \
    --query "Addresses[?PublicIp=='$ip'].[PublicIp,InstanceId,NetworkInterfaceId,AllocationId]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No Elastic IPs found"

  echo -e "\n🌐 NAT Gateways:"
  result=$(aws ec2 describe-nat-gateways \
    --region $region \
    --query "NatGateways[?NatGatewayAddresses[?PublicIp=='$ip' || PrivateIp=='$ip']].NatGatewayId" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No NAT Gateways found"

  echo -e "\n🚪 VPC Endpoints (via ENIs):"
  vpc_enis=$(aws ec2 describe-vpc-endpoints \
    --region $region \
    --query "VpcEndpoints[?PrivateDnsEnabled==\`true\`].NetworkInterfaceIds[]" \
    --output text)
  found=0
  for eni_id in $vpc_enis; do
    match=$(aws ec2 describe-network-interfaces --network-interface-ids $eni_id \
      --region $region \
      --query "NetworkInterfaces[?PrivateIpAddress=='$ip' || Association.PublicIp=='$ip'].NetworkInterfaceId" \
      --output text)
    if [[ -n "$match" ]]; then
      echo "✅ VPC Endpoint ENI $eni_id uses IP $ip"
      found=1
    fi
  done
  [[ $found -eq 0 ]] && echo "❌ No VPC Endpoint ENIs found using IP $ip"

  echo -e "\n⚖️ Load Balancer IP Match (via ENIs):"
  lb_enis=$(aws ec2 describe-network-interfaces \
    --filters Name=description,Values="ELB *" \
    --region $region \
    --query "NetworkInterfaces[?PrivateIpAddress=='$ip' || Association.PublicIp=='$ip'].NetworkInterfaceId" \
    --output text)
  if [[ -n "$lb_enis" ]]; then
    for eni in $lb_enis; do
      echo "✅ Load Balancer ENI $eni uses IP $ip"
    done
  else
    echo "❌ No Load Balancer ENIs found using IP $ip"
  fi

  echo -e "\n🧬 Lambda ENIs (via ENIs):"
  lambda_enis=$(aws ec2 describe-network-interfaces \
    --filters Name=description,Values="AWS Lambda VPC ENI*" \
    --region $region \
    --query "NetworkInterfaces[?PrivateIpAddress=='$ip' || Association.PublicIp=='$ip'].NetworkInterfaceId" \
    --output text)
  if [[ -n "$lambda_enis" ]]; then
    for eni in $lambda_enis; do
      echo "✅ Lambda ENI $eni uses IP $ip"
    done
  else
    echo "❌ No Lambda ENIs found using IP $ip"
  fi

  echo ""
done
