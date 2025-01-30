#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function show_usage() {
	echo
	echo "tf-apply.sh"
	echo
	echo "Runs a terraform apply"
	echo
	echo -e "\t--environment\t(Required)Environment name to deploy to"
	echo
}


# Set default values here
env_name=""


# Process switches:
while [[ $# -gt 0 ]]
do
	case "$1" in
		--environment)
			env_name=$2
			shift 2
			;;
		*)
			echo "Unexpected '$1'"
			show_usage
			exit 1
			;;
	esac
done


if [[ -z $env_name ]]; then
	echo "--environment must be specified"
	show_usage
	exit 1
fi

# Import .env if it exists and then check for required variables
if [[ -f .env ]];then
  echo "Found .env file - importing"
  source .env
else
  echo "No .env file found"
fi

if [[ -z $LOCATION ]]; then
  echo "LOCATION must be set"
  exit 1
fi

if [[ -z $RESOURCE_GROUP_BASE ]]; then
  echo "RESOURCE_GROUP_BASE must be set"
  exit 1
fi

if [[ -z $UNIQUE_ID ]]; then
  echo "UNIQUE_ID must be set"
  exit 1
fi

if [[ -z $ARM_SUBSCRIPTION_ID ]]; then
  echo "ARM_SUBSCRIPTION_ID must be set"
  exit 1
fi


resource_group_name="$RESOURCE_GROUP_BASE-$env_name"

cd $script_dir/../example

ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
terraform apply \
  -var "environment=$env_name" \
  -var "location=$LOCATION" \
  -var "resource_group_name=$resource_group_name" \
  -var "resource_suffix=$UNIQUE_ID" \
  -state "$env_name.tfstate" \
  -auto-approve