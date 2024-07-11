#!/bin/bash

# This script will swap the sandbox to a local instance of a service

TEMPFILE=.local-values.yaml

# Check for yq tool
if ! command -v yq &> /dev/null; then
	echo "yq tool could not be found, please install yq (https://github.com/mikefarah/yq/)"
	exit 1
fi

SERVICE=$(echo $1 | tr -s '/')
DIR=$(echo $2 | tr -s '/')

# Trim extra forward slashes
CHARTYAML=$(echo "$DIR/$SERVICE/chart/Chart.yaml" | tr -s '/')

# Verify that the Chart.yaml file exists
if [ ! -f "$CHARTYAML" ]; then
	echo "Service path not found: $CHARTYAML"
	exit 1
fi

touch $TEMPFILE

yq -i ".localrepos *=d [{\"name\":\"$SERVICE\", \"relpath\":\"$DIR\"}]" $TEMPFILE