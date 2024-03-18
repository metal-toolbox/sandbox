#!/bin/sh
# This is a helper script to purge all active conditions the KV
# A server uuid may be optionally passed in to remove any JS events that
# related to the server.

set -e

SERVERID="$1"

CPWD=$(pwd)
[[ "$(basename $CPWD)" != "sandbox" ]] && echo "This script should be executed from the repo top level directory" && exit 1

# restore nats accounts, creds which are backed up as part of nats-bootstrap,
# this allows the script auth and execute with nats through the nats-box
source scripts/nats-bootstrap/functions.sh
restore_accounts

function kv() {
	kubectl exec -ti deployments/nats-box -- /bin/sh -c \
		"NKEYS_PATH=/root/nsc/nkeys NSC_HOME=/root/nsc/accounts \
         nats -s nats://nats:4222 --creds=/root/nsc/nkeys/creds/KO/controllers/flipflop.creds kv $1"
}

function stream() {
	kubectl exec -ti deployments/nats-box -- /bin/sh -c \
		"NKEYS_PATH=/root/nsc/nkeys NSC_HOME=/root/nsc/accounts \
         nats -s nats://nats:4222 --creds=/root/nsc/nkeys/creds/KO/controllers/flipflop.creds stream $1"
}

function consumer() {
	kubectl exec -ti deployments/nats-box -- /bin/sh -c \
		"NKEYS_PATH=/root/nsc/nkeys NSC_HOME=/root/nsc/accounts \
         nats -s nats://nats:4222 --creds=/root/nsc/nkeys/creds/KO/controllers/flipflop.creds consumer $1"
}

if [[ ! -z $SERVERID ]]; then
	kv "rm -f active-conditions ${SERVERID}"
fi

for condition in serverControl firmwareInstall inventory; do
	restart=0
	keys=$(kv "ls ${condition}")
	if [[ ! "$keys" =~ "No keys" ]]; then
		for c in; do
			kv "rm -f ${condition} $c"
			restart=1
		done
	fi

	subject="com.hollow.sh.controllers.commands.sandbox.servers.${condition}"
	count=$(stream "subjects controllers $subject | sed -e 's/$subject://g' | tr -d '[:space:]'")

	controller=""
	case ${condition} in
	serverControl)
		controller="flipflop"
		;;
	firmwareInstall)
		controller="flasher"
		;;
	inventory)
		controller="alloy"
		;;
	esac

	if [[ ! "$count" =~ "Nosubjectsfound" ]]; then
		for c in $(seq 0 ${count}); do
			consumer "sub controllers sandbox-${controller}"
			restart=1
		done
	fi

	if [[ $restart -eq 1 ]]; then
		# restart controller pod incase its processing old events
		kubectl delete pod -l k8s-service=${controller}
	fi
done
