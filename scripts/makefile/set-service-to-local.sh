#!/bin/bash

# This script will swap the sandbox to a local instance of a service

TEMPFILE=.local-values.yaml

./scripts/makefile/functions.sh $1

# Check to make sure a service was specified
if [[ -z "$1" ]]; then
	echo "No service specified. Please add it like so: \"./scripts/makefile/info.sh <SERVICE> <DIR>\""
	exit 1
fi

# Check to make sure a directory was specified
if [[ -z "$2" ]]; then
	echo "No directory specified. Please add it like so: \"./scripts/makefile/info.sh <SERVICE> <DIR>\""
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