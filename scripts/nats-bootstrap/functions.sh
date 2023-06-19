#!/bin/sh

function clean_natsserver() {
	set +e
	kubectl get statefulsets | grep nats && make clean-nats

	set -e
}

function init_natsserver() {
	make local-devel-upgrade
}

function clean_natsbox() {
	kubectl exec -ti deployments/nats-box -- rm -rf /root/*.* /nsc
}

function init_natsaccounts() {

	kubectl exec -ti deployments/nats-box -- /bin/sh <<'EOF'

set -e

echo '
# NSC Environment Setup
export NKEYS_PATH=/root/nsc/nkeys
export NSC_HOME=/root/nsc/accounts
' > /root/.nsc.env

source /root/.nsc.env

mkdir -p $NSC_HOME
mkdir -p "$NKEYS_PATH"

# create operator account
nsc add operator --name KO
nsc edit operator --service-url nats://nats:4222
nsc edit operator --account-jwt-server-url nats://nats:4222

# Create system account - required to interact with the nats server
nsc add account --name SYS
nsc add user --name sys

# create servserservice Jetstream account - with permissions to list, create JS streams
nsc add account --name serverservice
nsc edit account --name serverservice --js-disk-storage 256M --js-mem-storage -1 --js-consumer -1 --js-streams -1

# generate a signing key to create a serverservice role
# so we can attach various pubsub permissions to the role
nsc edit account --sk generate --name serverservice
SK_S=$(nsc describe account serverservice -J | jq .nats.signing_keys[0] -r)
nsc edit signing-key -a serverservice --sk ${SK_S} --role serverservice

# https://docs.nats.io/reference/reference-protocols/nats_api_reference
nsc edit signing-key -a serverservice --sk ${SK_S} \
	--allow-pubsub '$JS.API.INFO' \
	--allow-pubsub '$JS.API.STREAM.INFO.serverservice' \
	--allow-pubsub '$JS.API.STREAM.NAMES' \
	--allow-pubsub '$JS.API.STREAM.LIST' \
	--allow-pubsub '$JS.API.STREAM.CREATE.serverservice' \
	--allow-pubsub '$JS.API.CONSUMER.NAMES.serverservice' \
	--allow-pubsub '$JS.API.CONSUMER.INFO.serverservice.>' \
	--allow-pubsub '$JS.API.CONSUMER.CREATE.serverservice.>' \
	--allow-pubsub '$JS.API.STREAM.DELETE.serverservice' \
	--allow-pubsub '$JS.API.CONSUMER.DELETE.serverservice.serverservice' \
	--allow-sub '_INBOX.>' \
	--allow-pubsub 'com.hollow.sh.serverservice.events.>'

# create serverservice user, with the serverservice role
nsc add user -a serverservice --name serverservice -K serverservice

# create controllers Jetstream account - with permissions to list, create JS streams
nsc add account --name controllers
nsc edit account --name controllers --js-disk-storage 256M --js-mem-storage -1 --js-consumer -1 --js-streams -1

# generate a signing key to create a controllers role
# so we can attach various pubsub permissions to the role
nsc edit account --sk generate --name controllers
SK_A=$(nsc describe account controllers -J | jq .nats.signing_keys[0] -r)
nsc edit signing-key -a controllers --sk ${SK_A} --role controllers

# https://docs.nats.io/reference/reference-protocols/nats_api_reference
nsc edit signing-key -a controllers --sk ${SK_A} \
	--allow-pubsub '$JS.API.INFO' \
	--allow-pubsub '$JS.API.STREAM.INFO.controllers' \
	--allow-pubsub '$JS.API.STREAM.NAMES' \
	--allow-pubsub '$JS.API.STREAM.LIST' \
	--allow-pubsub '$JS.API.STREAM.CREATE.controllers' \
	--allow-pubsub '$JS.API.STREAM.MSG.DELETE.controllers' \
	--allow-pubsub '$JS.API.STREAM.MSG.GET.controllers' \
	--allow-pubsub '$JS.API.CONSUMER.NAMES.controllers' \
	--allow-pubsub '$JS.API.CONSUMER.INFO.controllers.>' \
	--allow-pubsub '$JS.API.CONSUMER.CREATE.controllers.>' \
	--allow-pubsub '$JS.API.CONSUMER.MSG.NEXT.controllers.>' \
	--allow-pubsub '$JS.API.CONSUMER.DELETE.controllers.>' \
	--allow-pubsub '$JS.API.STREAM.INFO.KV_active-controllers' \
    --allow-pubsub '$JS.API.STREAM.CREATE.KV_active-controllers' \
	--allow-pubsub '$JS.ACK.controllers.>' \
	--allow-sub 'com.hollow.sh.serverservice.events.>' \
	--allow-pubsub 'com.hollow.sh.controllers.>' \
	--allow-sub 'com.hollow.sh.controllers.commands.>' \
	--allow-pubsub 'com.hollow.sh.controllers.responses' \
	--allow-sub '_INBOX.>'

# create conditionorc user, with the controllers role
nsc add user -a controllers --name conditionorc -K controllers

# create alloy user, with the controllers role
nsc add user -a controllers --name alloy -K controllers

# create flasher user, with the controllers role
nsc add user -a controllers --name flasher -K controllers


EOF
}

function kuexec() {
	kubectl exec -ti deployments/nats-box -- /bin/sh -c \
		"NKEYS_PATH=/root/nsc/nkeys NSC_HOME=/root/nsc/accounts && $1"
}

function push_natsaccounts() {
	while ! kubectl logs statefulsets/nats nats | head -100 | grep "Server is ready"; do
		echo "waiting for nats server to be ready to push accounts... "
		sleep 5
	done

	sleep 10
	kuexec "nsc push --system-account SYS -u nats://nats:4222 -A"
}

function update_valuesyaml() {
	set -x
	f=values.yaml.bk
	cp values.yaml $f

	CURRENT_OPKEY=$(awk '/operator: /{print $2}' $f)
	CURRENT_SYSKEY=$(awk '/systemAccount: /{print $2}' $f)
	CURRENT_SYSPRELOADKEY=$(grep resolverPreload -a1 $f | grep $CURRENT_SYSKEY | awk -F': ' '/: /{print $2}')

	OPKEY=$(kuexec "nsc generate config --sys-account SYS --nats-resolver | awk  '/operator: /{print \$2}' | tr -d '\\r' ")
	SYSKEY=$(kuexec "nsc generate config --sys-account SYS --nats-resolver | awk '/system_account: /{print \$2}' | tr -d '\\r' ")
	SYSPRELOADKEY=$(kuexec "nsc generate config --sys-account SYS  --nats-resolver |  \
    grep resolver_preload -A1 | sed -e 's/,//g' -e 's/{//g'  | awk -F': ' '/: /{print \$2}' | tr -d '\r' ")

	OPKEY=$(echo $OPKEY | tr -d '\r')
	SYSKEY=$(echo $SYSKEY | tr -d '\r')
	SYSPRELOADKEY=$(echo $SYSPRELOADKEY | tr -d '\n' | tr -d '\r' | tr -d ' ')
	sed -ie 's/operator: '${CURRENT_OPKEY}'/operator: '${OPKEY}'/' $f
	sed -ie 's/systemAccount: '${CURRENT_SYSKEY}'/systemAccount: '${SYSKEY}'/' $f
	sed -ie 's/'${CURRENT_SYSKEY}': '${CURRENT_SYSPRELOADKEY}'/'${SYSKEY}': '${SYSPRELOADKEY}'/' $f

	mv $f values.yaml
}

function push_controller_secrets() {
	for controller in conditionorc alloy flasher; do
		sekrit=$(kuexec "cat /root/nsc/nkeys/creds/KO/controllers/${controller}.creds" | base64)

		echo "apiVersion: v1
metadata:
  name: ${controller}-secrets
  namespace: default
data:
  ${controller}-nats-creds: $sekrit
kind: Secret
type: Opaque" >/tmp/kind_${controller}_secret.yaml

		kubectl apply -f /tmp/kind_${controller}_secret.yaml
	done
}

function push_serverservice_secrets() {
	sekrit=$(kuexec "cat /root/nsc/nkeys/creds/KO/serverservice/serverservice.creds" | base64)

	echo "apiVersion: v1
metadata:
  name: serverservice-secrets
  namespace: default
data:
  serverservice-nats-creds: $sekrit
kind: Secret
type: Opaque" >/tmp/kind_serverservice_secret.yaml

	kubectl apply -f /tmp/kind_serverservice_secret.yaml
}

function backup_accounts() {
	kuexec "tar -czf nats-accounts.tar.gz /root/nsc /nsc"
	kubectl cp $(kubectl get pods | awk '/nats-box/{print $1}'):/nats-accounts.tar.gz ./scripts/nats-bootstrap/nats-accounts.tar.gz
}
