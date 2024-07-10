#!/bin/bash

# This script will swap the sandbox to a upstream instance of a service

if ! command -v yq &> /dev/null; then
	echo "yq tool could not be found, please install yq (https://github.com/mikefarah/yq/)"
	exit 1
fi

# Check to make sure a service was specified
if [[ -z "$1" ]]; then
	echo "No service specified. Please add it like so: \"make local SERVICE=<MY-SERVICE>\""
	exit 1
fi
SERVICE=$1

touch .local-values.yaml

# Get backed up Chart.yaml info
OLDCHARTVERSION=$(yq ".chartbackup.$SERVICE.version" .local-values.yaml)
OLDCHARTREPO=$(yq ".chartbackup.$SERVICE.repository" .local-values.yaml)

# Delete docker image info so its no longer overriden
yq -i "del(.$SERVICE)" .local-values.yaml

# Revert Chart.yaml info
yq -i "(.dependencies.[] | select(.name == \"$SERVICE\") | .version) = \"$OLDCHARTVERSION\"" Chart.yaml
yq -i "(.dependencies.[] | select(.name == \"$SERVICE\") | .repository) = \"$OLDCHARTREPO\"" Chart.yaml
yq -i "del(.chartbackup.$SERVICE)" .local-values.yaml