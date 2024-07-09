#!/bin/bash

# This script will swap the sandbox to a local instance of a service

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

# Check for non default location of a service
DIR="../"
if [[ -n "$2" ]]; then
	DIR=$2
fi

# Trim extra forward slashes. In case DIR has slashes in it
SERVICEDIR=$(echo "$DIR/$SERVICE" | tr -s '/')

# Verify that the service exists
if [ ! -d "$SERVICEDIR" ]; then
	echo "Service directory: $SERVICEDIR doesnt exist."
	exit 1
fi


# Trim extra forward slashes. In case SERVICEDIR ends in a slashes
CHARTDIR=$(echo "$SERVICEDIR/chart" | tr -s '/')

# Verify that the chart exists
if [ ! -d "$CHARTDIR" ]; then
	echo "Chart directory: $CHARTDIR doesnt exist."
	exit 1
fi

# Trim extra forward slashes. In case SERVICEDIR ends in a slashes
CHARTYAML=$(echo "$CHARTDIR/Chart.yaml" | tr -s '/')

# Verify that the Chart.yaml file exists
if [ ! -f "$CHARTYAML" ]; then
	echo "Chart.yaml: $CHARTYAML doesnt exist."
	exit 1
fi


touch .local-values.yaml

# Backup current Chart.yaml info only if not already backed up
OLDCHARTVERSION=$(yq ".chartbackup.$SERVICE.version" .local-values.yaml)
OLDCHARTREPO=$(yq ".chartbackup.$SERVICE.repository" .local-values.yaml)
if [[ "$OLDCHARTVERSION" == "null" ]] && [[ "$OLDCHARTREPO" == "null" ]]; then
	OLDCHARTVERSION=$(yq ".dependencies.[] | select(.name == \"$SERVICE\") | .version" Chart.yaml)
	OLDCHARTREPO=$(yq ".dependencies.[] | select(.name == \"$SERVICE\") | .repository" Chart.yaml)
	yq -i ".chartbackup.$SERVICE.version=\"$OLDCHARTVERSION\"" .local-values.yaml
	yq -i ".chartbackup.$SERVICE.repository=\"$OLDCHARTREPO\"" .local-values.yaml
fi

# Set docker image location
CHARTVERSION=$(cat $CHARTYAML | yq ".version")
yq -i ".$SERVICE.image.repository.url=\"localhost:5001\"" .local-values.yaml
yq -i ".$SERVICE.image.repository.tag=\"$CHARTVERSION\"" .local-values.yaml

# Set Chart.yaml info
yq -i "(.dependencies.[] | select(.name == \"$SERVICE\") | .version) = \"$CHARTVERSION\"" Chart.yaml
yq -i "(.dependencies.[] | select(.name == \"$SERVICE\") | .repository) = \"file://$CHARTDIR\"" Chart.yaml