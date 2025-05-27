#!/bin/bash

# ------------------------------------------------------------------
# Script: search-vpc-flow-ip-us.sh
# Purpose: Search VPC Flow Logs in CloudWatch for a specific IP across key U.S. AWS regions
# Author: Trevor Edwards (GCK)
# ------------------------------------------------------------------

# === Configuration ===
ip="34.222.182.236"                 # IP address to search
log_group="VPCFlowLog"            # CloudWatch log group name
profile="default"                 # AWS CLI profile name
lookback_minutes=60               # Time window in minutes

# === Time Range Calculation ===
end_time=$(date +%s)
start_time=$((end_time - lookback_minutes * 60))

# === U.S. AWS Regions to Search ===
regions=(us-west-1 us-west-2 us-east-1 us-east-2)

echo "==================================================================="
echo "🔍 Searching VPC Flow Logs for IP: $ip"
echo "Log Group: $log_group | Profile: $profile | Time Window: $lookback_minutes min"
echo "Regions: ${regions[*]}"
echo "==================================================================="

for region in "${regions[@]}"; do
  echo ""
  echo "---------------------------------------------------------------"
  echo "🌍 Region: $region"
  echo "---------------------------------------------------------------"

  # Check if log group exists in this region
  log_group_check=$(aws logs describe-log-groups \
    --log-group-name-prefix "$log_group" \
    --region "$region" \
    --profile "$profile" \
    --query "logGroups[?logGroupName=='$log_group']" \
    --output text 2>/dev/null)

  if [[ -z "$log_group_check" ]]; then
    echo "⚠️  Log group '$log_group' not found in $region. Skipping."
    continue
  fi

  # Run the search
  result=$(aws logs filter-log-events \
    --log-group-name "$log_group" \
    --start-time "$((start_time * 1000))" \
    --end-time "$((end_time * 1000))" \
    --filter-pattern "$ip" \
    --region "$region" \
    --profile "$profile" \
    --max-items 100 \
    --output json 2>/dev/null)

  if [[ $? -ne 0 || -z "$result" ]]; then
    echo "❌ Error while querying logs in $region. Skipping."
    continue
  fi

  # Check result contents
  match_count=$(echo "$result" | jq '.events | length')
  if [[ "$match_count" -gt 0 ]]; then
    echo "✅ $match_count matches found in $region:"
    echo "$result" | jq '.events[] | {timestamp, logStreamName, message}'
  else
    echo "❌ No matches found in $region."
  fi
done

echo ""
echo "✅ Search complete."
