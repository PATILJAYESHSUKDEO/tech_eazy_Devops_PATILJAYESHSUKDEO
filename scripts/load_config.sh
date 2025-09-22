#!/bin/bash

STAGE=$1
if [ -z "$STAGE" ]; then
  echo "Please supply stage: Dev or Prod"
  exit 1
fi

# convert to lowercase
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')
CONFIG_FILE="config/${STAGE_LOWER}_config"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file ${CONFIG_FILE} does not exist"
  exit 1
fi

source "$CONFIG_FILE"

echo "Loaded config for Stage: ${STAGE}"
echo "INSTANCE_TYPE = $INSTANCE_TYPE"
echo "KEY_NAME = $KEY_NAME"
echo "SECURITY_GROUP_NAME = $SECURITY_GROUP_NAME"
echo "REGION = $REGION"
echo "REPO_URL = $REPO_URL"
echo "STAGE = $STAGE"

