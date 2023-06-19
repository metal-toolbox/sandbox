#!/bin/sh

set -e

CPWD=$(PWD)
[[ "$(basename $CPWD)" != "sandbox" ]] && echo "This script should be executed from the repo top level directory" && return 1

echo "Note: this will purge all current NATS related k8s objects and services"
echo "before proceeding make sure any changes to values.yaml has been commited or backed up..."
echo "hit enter to proceed ..."

read

source scripts/nats-bootstrap/functions.sh

clean_natsbox
clean_natsserver
init_natsaccounts
update_valuesyaml
init_natsserver
push_natsaccounts
push_controller_secrets
push_serverservice_secrets
backup_accounts
