#!/bin/bash

set -e

CPWD=$(pwd)
[[ "$(basename $CPWD)" != "sandbox" ]] && echo "This script should be executed from the repo top level directory" && exit 1

echo "Note: this will purge all current NATS related k8s objects and services"
echo "before proceeding make sure any changes to values.yaml has been commited or backed up..."
echo "hit enter to proceed ..."

read

source scripts/nats-bootstrap/functions.sh

clean_natsbox
clean_natsserver
init_natsaccounts
update_values_nats_yaml
init_natsserver
push_natsaccounts

if [ "$(uname)" == "Darwin" ]; then
	push_controller_secrets_macos
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	push_controller_secrets_linux
else
	echo "Unknown OS detected! push_controller_secrets not called!"
fi

reload_controller_deployments

if [ "$(uname)" == "Darwin" ]; then
	push_serverservice_secrets_macos
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	push_serverservice_secrets_linux
else
	echo "Unknown OS detected! push_serverservice_secrets not called!"
fi

backup_accounts
