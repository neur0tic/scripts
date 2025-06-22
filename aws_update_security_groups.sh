#!/bin/bash
# Author: Azwan Ngali (azwan.ngali@gmail.com)
# Usage: ./your_script.sh --sg <SecurityGroupID> --sgr <SecurityGroupRuleID>
# Example: ./your_script.sh --sg sg-0ba44c1bf92d19607 --sgr sgr-0ac78f96823c2faef
#
# This script updates the specified security group rule with the current IP address
# and a description containing the current date.
#
# Prerequisites:
# 1. AWS CLI must be installed on your system.
# 2. AWS CLI must be configured with appropriate permissions to modify security group rules.
# 3. The script must be executed in an environment with internet access to fetch the current IP address.

export PATH="/usr/local/bin:/usr/bin:/bin"

# Initialize variables
SEC_GROUP_ID=""
SEC_GROUP_RULE_ID=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --sg) SEC_GROUP_ID="$2"; shift ;;
        --sgr) SEC_GROUP_RULE_ID="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate input (basic validation)
if [[ -z "$SEC_GROUP_ID" || -z "$SEC_GROUP_RULE_ID" ]]; then
    echo "Usage: $0 --sg <SecurityGroupID> --sgr <SecurityGroupRuleID>"
    exit 1
fi

if [[ ! "$SEC_GROUP_ID" =~ ^sg-[0-9a-f]{8,}$ ]]; then
    echo "Invalid Security Group ID format."
    exit 1
fi

if [[ ! "$SEC_GROUP_RULE_ID" =~ ^sgr-[0-9a-f]{8,}$ ]]; then
    echo "Invalid Security Group Rule ID format."
    exit 1
fi

# Gets current date and prepares description for sec group rule
CURRENT_DATE=$(date +'%Y-%m-%d')
SEC_GROUP_RULE_DESCRIPTION="Home Dynamic IP Update - ${CURRENT_DATE}"

# Gets current I.P. and adds /32 for ipv4 cidr
CURRENT_IP=$(curl --silent https://checkip.amazonaws.com)
NEW_IPV4_CIDR="${CURRENT_IP}/32"

# Updates I.P. and description in the sec group rule
aws ec2 modify-security-group-rules --group-id "${SEC_GROUP_ID}" --security-group-rules "SecurityGroupRuleId=${SEC_GROUP_RULE_ID},SecurityGroupRule={CidrIpv4=${NEW_IPV4_CIDR},IpProtocol=tcp,FromPort=22,ToPort=22,Description=${SEC_GROUP_RULE_DESCRIPTION}}"

# Shows the sec group rule updated
aws ec2 describe-security-group-rules --filter "Name=security-group-rule-id,Values=${SEC_GROUP_RULE_ID}"
