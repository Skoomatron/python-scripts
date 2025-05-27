#!/bin/bash

# A comprehensive shell script that searches multiple AWS resource types tied to a
# specific private IP address across multiple regions. It includes:
# - EC2 Instances
# - ENIs (Elastic Network Interfaces)
# - NAT Gateways
# - VPC Endpoints (via ENIs)
# - Load Balancers (NLB/ALB, via ENIs)
# - Lambda ENIs

ip="54.153.28.209"
regions=(us-west-1 us-west-2 us-east-1 us-east-2)

for region in "${regions[@]}"; do
  echo "===================================================="
  echo "🔍 Searching for IP: $ip in region: $region"
  echo "===================================================="

  echo -e "\n📦 EC2 Instances:"
  result=$(aws ec2 describe-instances \
    --filters Name=private-ip-address,Values=$ip \
    --region $region \
    --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No EC2 instances found"

  echo -e "\n🔌 Network Interfaces (ENIs):"
  result=$(aws ec2 describe-network-interfaces \
    --filters Name=private-ip-address,Values=$ip \
    --region $region \
    --query "NetworkInterfaces[*].[NetworkInterfaceId,PrivateIpAddress,Description,Attachment.InstanceId,TagSet]" \
    --output json)
  echo "$result"
  [[ "$result" == "[]" ]] && echo "❌ No ENIs found"

  echo -e "\n🌐 NAT Gateways:"
  result=$(aws ec2 describe-nat-gateways \
    --region $region \
    --query "NatGateways[?NatGatewayAddresses[?PrivateIp=='$ip']].NatGatewayId" \
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
      --query "NetworkInterfaces[?PrivateIpAddress=='$ip'].NetworkInterfaceId" \
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
    --query "NetworkInterfaces[?PrivateIpAddress=='$ip'].NetworkInterfaceId" \
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
    --query "NetworkInterfaces[?PrivateIpAddress=='$ip'].NetworkInterfaceId" \
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
