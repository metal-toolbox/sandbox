#!/bin/sh

set -e

export NKEYS_PATH=/root/nsc/nkeys
export NSC_HOME=/root/nsc/accounts

if [ ! -f .nsc.env ]; then
	echo '
# NSC Environment Setup
export NKEYS_PATH=/root/nsc/nkeys
export NSC_HOME=/root/nsc/accounts
' >nsc.env
fi

mkdir -p "$NKEYS_PATH"
mkdir -p "$NSC_HOME"

# create operator account
nsc add operator --name KO
nsc edit operator --service-url nats://nats:4222
nsc edit operator --account-jwt-server-url nats://nats:4222

# Create system account - required to interact with the nats server
nsc add account --name SYS
nsc add user --name sys

# create servserservice Jetstream account - with permissions to list, create JS streams
nsc add account --name serverservice
nsc edit account --name serverservice --js-mem-storage -1 --js-consumer -1 --js-streams -1

# generate a signing key to create a serverservice role
# so we can attach various pubsub permissions to the role
nsc edit account --sk generate --name serverservice
SK_S=$(nsc describe account serverservice -J | jq .nats.signing_keys[0] -r)
nsc edit signing-key -a serverservice --sk ${SK_S} --role serverservice
nsc edit signing-key -a serverservice --sk ${SK_S} \
	--allow-pubsub '$JS.API.INFO' \
	--allow-pubsub '$JS.API.STREAM.NAMES' \
	--allow-pubsub '$JS.API.STREAM.LIST' \
	--allow-pubsub '$JS.API.STREAM.CREATE.serverservice' \
	--allow-sub '_INBOX.>' \
	--allow-pubsub 'com.hollow.sh.serverservice.events.>'

# create serverservice user, with the serverservice role
nsc add user -a serverservice --name serverservice -K serverservice

# create controllers Jetstream account - with permissions to list, create JS streams
nsc add account --name controllers
nsc edit account --name controllers --js-mem-storage -1 --js-consumer -1 --js-streams -1

# generate a signing key to create a controllers role
# so we can attach various pubsub permissions to the role
nsc edit account --sk generate --name controllers
SK_A=$(nsc describe account controllers -J | jq .nats.signing_keys[0] -r)
nsc edit signing-key -a controllers --sk ${SK_A} --role controllers
nsc edit signing-key -a controllers --sk ${SK_A} \
	--allow-pubsub '$JS.API.INFO' \
	--allow-pubsub '$JS.API.STREAM.NAMES' \
	--allow-pubsub '$JS.API.STREAM.LIST' \
	--allow-pubsub '$JS.API.STREAM.CREATE.controllers' \
	--allow-sub 'com.hollow.sh.serverservice.events.>' \
	--allow-pubsub 'com.hollow.sh.controllers.>' \
	--allow-sub 'com.hollow.sh.controllers.commands.>' \
	--allow-pubsub 'com.hollow.sh.controllers.responses' \
	--allow-sub '_INBOX.>'

# create conditionorc user, with the controllers role
nsc add user -a controllers --name conditionorc -K controllers

# create alloy user, with the controllers role
nsc add user -a controllers --name alloy -K controllers

nsc generate config --sys-account SYS --nats-resolver
echo ">>> accounts generated, now follow steps below.."
echo "1. update values.yaml with Operator, SYS, Resolver Preload values from the above output."
echo "2. update the nats-server helm install - make local-devel-upgrade."
echo "3. make sure the nats-server pod is restarted - and indicates its running."
echo "4. hit enter when ready - this will push the accounts to the nats server."
read

source nsc.env

echo ">>> pushing accounts to nats-server..."
nsc push --system-account SYS -u nats://nats:4222 -A

cat /root/nsc/nkeys/creds/KO/serverservice/serverservice.creds
echo ">> add the above creds into templates/serverservice-nats-creds-configmap.yaml, press enter when done..."
read

cat /root/nsc/nkeys/creds/KO/controllers/alloy.creds
echo ">> add the above creds into templates/alloy-nats-creds-configmap.yaml, press enter when done..."
read

cat /root/nsc/nkeys/creds/KO/controllers/conditionorc.creds
echo ">>> add the above creds into templates/conditionorc-nats-creds-configmap.yaml, press enter when done..."
read

echo ">>> creating tarball with nsc accounts to restore these accounts"
cd /
tar -cvzf nats-accounts.tar.gz /root/nsc /nsc
echo ">>> copy over /nats-accounts.tar.gz locally"
echo "use kubectl cp $(hostname):/nats-accounts.tar.gz nats-accounts.tar.gz"
echo "hit enter when complete..."
read
echo "all done."
