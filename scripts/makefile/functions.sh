#!/bin/bash

# This script will do some checks about availability of commands and input variables.

TEMPFILE=.local-values.yaml
touch $TEMPFILE

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