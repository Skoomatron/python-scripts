#!/bin/bash

# ------------------------------------------------------------------
# Script: search-vpc-flow-ip-all-regions.sh
# Purpose: Search CloudWatch VPC Flow Logs for a given IP across all AWS regions
# Author: Trevor Edwards (GCK)
# ------------------------------------------------------------------

# === Configuration ===
ip="54.153.28.209"                 # IP address to search
log_group="VPCFlowLog"            # Name of CloudWatch Log Group
profile="default"                 # AWS CLI profile
lookback_minutes=60              # Time window to search (in minutes)

# === Derived time range ===
end_time=$(date +%s)
start_time=$((end_time - lookback_minutes * 60))

# === List of commercial AWS regions ===
regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text --profile "$profile")

echo "==================================================================="
echo "🔍 Searching VPC Flow Logs for IP: $ip"
echo "Log Group: $log_group | Lookback: $lookback_minutes min"
echo "Regions: $regions"
echo "==================================================================="

for region in $regions; do
  echo ""
  echo "---------------------------------------------------------------"
  echo "🌍 Region: $region"
  echo "---------------------------------------------------------------"

  result=$(aws logs filter-log-events \
    --log-group-name "$log_group" \
    --start-time "$((start_time * 1000))" \
    --end-time "$((end_time * 1000))" \
    --filter-pattern "$ip" \
    --region "$region" \
    --profile "$profile" \
    --max-items 100 \
    --output json 2>/dev/null)

  if [[ $(echo "$result" | jq '.events | length') -gt 0 ]]; then
    echo "✅ Matches found:"
    echo "$result" | jq '.events[] | {timestamp, logStreamName, message}'
  else
    echo "❌ No matches found."
  fi
done

echo ""
echo "✅ Done."
