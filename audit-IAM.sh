#!/bin/bash

# Prerequisites: AWS CLI and jq installed and configured

echo "📋 Fetching all IAM roles..."
ALL_ROLES=$(aws iam list-roles \
  --query "Roles[?!(starts_with(Path, '/aws-service-role/') || contains(Arn, 'aws-service-role'))].RoleName" \
  --output text)

echo "🔍 Checking EC2 instance profiles..."
EC2_ROLES=$(aws ec2 describe-instances \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn" --output text | \
  xargs -n1 basename | \
  xargs -I{} aws iam get-instance-profile --instance-profile-name {} \
    --query "InstanceProfile.Roles[*].RoleName" --output text)

echo "🔍 Checking Lambda execution roles..."
LAMBDA_ROLES=$(aws lambda list-functions \
  --query "Functions[*].Role" --output text | \
  xargs -n1 basename)

echo "🔍 Checking ECS task roles..."
ECS_TASK_DEFS=$(aws ecs list-task-definitions --query 'taskDefinitionArns[*]' --output text)
ECS_ROLES=""
for DEF in $ECS_TASK_DEFS; do
  OUTPUT=$(aws ecs describe-task-definition --task-definition $DEF 2>/dev/null)
  ECS_ROLES+=$(echo "$OUTPUT" | jq -r '.taskDefinition | [.taskRoleArn, .executionRoleArn] | @tsv')$'\n'
done
ECS_ROLES=$(echo "$ECS_ROLES" | awk '{print $1"\n"$2}' | grep -v null | xargs -n1 basename 2>/dev/null)

# Combine all attached roles
ATTACHED_ROLES=$(echo -e "$EC2_ROLES\n$LAMBDA_ROLES\n$ECS_ROLES" | sort | uniq)

echo "📊 Analyzing roles..."

for ROLE in $ALL_ROLES; do
  if echo "$ATTACHED_ROLES" | grep -q "^$ROLE$"; then
    echo "✅ $ROLE is attached to a service"
  else
    echo "⚠️  $ROLE is NOT attached to EC2/Lambda/ECS (potentially unused)"
  fi
done

echo
echo "👤 Auditing IAM users..."

USERS=$(aws iam list-users --query "Users[*].UserName" --output text)

for USER in $USERS; do
  LAST_LOGIN=$(aws iam get-user --user-name $USER \
    --query "User.PasswordLastUsed" --output text 2>/dev/null)

  KEY1_LASTUSED=$(aws iam list-access-keys --user-name $USER \
    --query "AccessKeyMetadata[0].AccessKeyId" --output text | \
    xargs -I{} aws iam get-access-key-last-used --access-key-id {} \
    --query "AccessKeyLastUsed.LastUsedDate" --output text 2>/dev/null)

  if [[ "$LAST_LOGIN" == "None" && "$KEY1_LASTUSED" == "None" ]]; then
    echo "⚠️  $USER has no console login or key usage — potentially unused"
  else
    echo "✅ $USER is active (Login: $LAST_LOGIN, Key use: $KEY1_LASTUSED)"
  fi
done
