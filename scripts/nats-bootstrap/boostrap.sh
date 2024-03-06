#!/bin/bash

set -e

CPWD=$(pwd)
[[ "$(basename $CPWD)" != "sandbox" ]] && echo "This script should be executed from the repo top level directory" && exit 1

echo "!! Note: this will purge all current NATS related k8s objects and services !!"
echo "before proceeding make sure any changes to values.yaml has been commited or backed up..."
echo ""
echo ">> \e[31m Hit enter to proceed \e[0m"

read

source scripts/nats-bootstrap/functions.sh

clean_natsbox
clean_natsserver
init_natsaccounts
update_values_nats_yaml
init_natsserver
push_natsaccounts
push_controller_secrets
reload_controller_deployments
backup_accounts
