#!/bin/bash

# This script will get some info about a service.

TEMPFILE=.local-values.yaml

# Check for yq
if ! command -v yq &> /dev/null; then
	echo "yq tool could not be found, please install yq (https://github.com/mikefarah/yq/)"
	exit 1
fi

# Check for git
if ! command -v git &> /dev/null; then
	echo "git tool could not be found, please install git (https://github.com/git/git)"
	exit 1
fi

# Check to make sure a service was specified
if [[ -z "$1" ]]; then
	echo "No service specified. Please add it like so: \"./scripts/makefile/info.sh <SERVICE>\""
	exit 1
fi
SERVICE=$1

touch $TEMPFILE

DOCKER_URL=$(yq ".$SERVICE.image.repository.url" $TEMPFILE)
if [[ "$DOCKER_URL" == "null" ]]; then
	DOCKER_URL=$(yq ".$SERVICE.image.repository.url" values.yaml)
fi

DOCKER_TAG=$(yq ".$SERVICE.image.repository.tag" $TEMPFILE)
if [[ "$DOCKER_TAG" == "null" ]]; then
	DOCKER_TAG=$(yq ".$SERVICE.image.repository.tag" values.yaml)
fi

CHART_URL=$(yq ".dependencies.[] | select(.name == \"$SERVICE\") | .repository" Chart.yaml)
CHART_TAG=$(yq ".dependencies.[] | select(.name == \"$SERVICE\") | .version" Chart.yaml)

echo ""

echo "Docker URL: $DOCKER_URL/$SERVICE"
echo "Docker TAG: $DOCKER_TAG"

echo ""

echo "Helm URL: $CHART_URL"
echo "Helm TAG: $CHART_TAG"

echo ""

# If using local, get some git info
if [[ $CHART_URL == *"file://"* ]]; then
	REPO=${CHART_URL:7:-5}
	cd $REPO
	BRANCH=$(git symbolic-ref -q HEAD)
	BRANCH=${BRANCH##refs/heads/}
	BRANCH=${BRANCH:-HEAD}
	DIFF=$(git diff --shortstat 2> /dev/null | tail -n1)
	echo "GIT REPO  : $REPO"
	echo "GIT BRANCH: $BRANCH"
	echo "GIT DIFFS : $DIFF"
	echo ""
fi