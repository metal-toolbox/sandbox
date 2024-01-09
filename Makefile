.DEFAULT_GOAL := help

CONDITION_ORC_PORT=9001
ALLOY_PORT=9091
FLEETDB_PORT=8000
CRDB_PORT=26257
CHAOS_DASH_PORT=2333
JAEGER_DASH_PORT=16686
MINIO_PORT=9000

## install helm chart for the sandbox env with fleetdb(default)
install: kubectl-ctx-kind
	sed -i -e 's/use_serverservice: true/use_serverservice: false/g' ./values.yaml
	cp ./scripts/nats-bootstrap/values-nats.yaml.tmpl values-nats.yaml
	helm install hollow-sandbox . -f values.yaml -f values-nats.yaml
	kubectl get pod
	./scripts/nats-bootstrap/boostrap.sh

## install helm chart for the sandbox env with hollow serverservice
install-hss: kubectl-ctx-kind
	sed -i -e 's/use_serverservice: false/use_serverservice: true/g' ./values.yaml
	cp ./scripts/nats-bootstrap/values-nats.yaml.tmpl values-nats.yaml
	helm install hollow-sandbox . -f values.yaml -f values-nats.yaml
	kubectl get pod
	./scripts/nats-bootstrap/boostrap.sh

## upgrade helm chart for the sandbox environment
upgrade: kubectl-ctx-kind
	helm upgrade hollow-sandbox . -f values.yaml -f values-nats.yaml

## uninstall helm chart
clean: kubectl-ctx-kind
	helm uninstall hollow-sandbox
	rm values-nats.yaml
	# incase the crdb pvc is stuck in terminating
	# kubectl patch pvc db -p '{"metadata":{"finalizers":null}}'

## port forward condition orchestrator API  (runs in foreground)
port-forward-conditionorc-api: kubectl-ctx-kind
	kubectl port-forward deployment/conditionorc-api ${CONDITION_ORC_PORT}:${CONDITION_ORC_PORT}

## port forward condition Alloy pprof endpoint  (runs in foreground)
port-forward-alloy-pprof: kubectl-ctx-kind
	kubectl port-forward deployment/alloy ${ALLOY_PORT}:${ALLOY_PORT}

## port forward hollow server service port (runs in foreground)
port-forward-hss: kubectl-ctx-kind
	kubectl port-forward deployment/serverservice ${FLEETDB_PORT}:${FLEETDB_PORT}

## port forward fleetdb port (runs in foreground)
port-forward-fleetdb: kubectl-ctx-kind
	kubectl port-forward deployment/fleetdb ${FLEETDB_PORT}:${FLEETDB_PORT}

## port forward crdb service port (runs in foreground)
port-forward-crdb: kubectl-ctx-kind
	kubectl port-forward deployment/crdb ${CRDB_PORT}:${CRDB_PORT}

## port forward fleetdb crdb service port (runs in foreground)
port-forward-fleetdb-crdb: kubectl-ctx-kind
	kubectl port-forward deployment/fleetdb-crdb ${CRDB_PORT}:${CRDB_PORT}

## port forward chaos-mesh dashboard (runs in foreground)
port-forward-chaos-dash: kubectl-ctx-kind
	kubectl port-forward service/chaos-dashboard ${CHAOS_DASH_PORT}:${CHAOS_DASH_PORT}

## port forward jaeger frontend
port-forward-jaeger-dash:
	kubectl port-forward service/jaeger ${JAEGER_DASH_PORT}:${JAEGER_DASH_PORT}

## port forward to the minio S3 port
port-forward-minio:
	kubectl port-forward deployment/minio ${MINIO_PORT}:${MINIO_PORT}

## port forward all endpoints (runs in the background)
port-all-with-lan:
	kubectl port-forward deployment/conditionorc-api --address 0.0.0.0 ${CONDITION_ORC_PORT}:${CONDITION_ORC_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/alloy --address 0.0.0.0 ${ALLOY_PORT}:${ALLOY_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/serverservice --address 0.0.0.0 ${FLEETDB_PORT}:${FLEETDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/crdb --address 0.0.0.0 ${CRDB_PORT}:${CRDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/fleetdb --address 0.0.0.0 ${FLEETDB_PORT}:${FLEETDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/fleetdb-crdb --address 0.0.0.0 ${CRDB_PORT}:${CRDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward service/chaos-dashboard --address 0.0.0.0 ${CHAOS_DASH_PORT}:${CHAOS_DASH_PORT} > /dev/null 2>&1 &
	kubectl port-forward service/jaeger --address 0.0.0.0 ${JAEGER_DASH_PORT}:${JAEGER_DASH_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/minio --address 0.0.0.0 ${MINIO_PORT}:${MINIO_PORT} > /dev/null 2>&1

port-all:
	kubectl port-forward deployment/conditionorc-api ${CONDITION_ORC_PORT}:${CONDITION_ORC_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/alloy ${ALLOY_PORT}:${ALLOY_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/serverservice ${FLEETDB_PORT}:${FLEETDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/crdb ${CRDB_PORT}:${CRDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/fleetdb ${FLEETDB_PORT}:${FLEETDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/fleetdb-crdb ${CRDB_PORT}:${CRDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward service/chaos-dashboard ${CHAOS_DASH_PORT}:${CHAOS_DASH_PORT} > /dev/null 2>&1 &
	kubectl port-forward service/jaeger ${JAEGER_DASH_PORT}:${JAEGER_DASH_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/minio ${MINIO_PORT}:${MINIO_PORT} > /dev/null 2>&1

## kill all port fowarding processes that are running in the background
kill-all-ports:
	lsof -i:${CONDITION_ORC_PORT} -t | xargs kill
	lsof -i:${ALLOY_PORT} -t | xargs kill
	lsof -i:${FLEETDB_PORT} -t | xargs kill
	lsof -i:${CRDB_PORT} -t | xargs kill
	lsof -i:${CHAOS_DASH_PORT} -t | xargs kill
	lsof -i:${JAEGER_DASH_PORT} -t | xargs kill
	lsof -i:${MINIO_PORT} -t | xargs kill

## install extra services used to test firmware-syncer
firmware-syncer-env:
	helm upgrade hollow-sandbox . -f values.yaml -f values-nats.yaml --set syncer.enable_env=true
	./scripts/minio-dns-setup.sh set

## Remove extra services installed for firmware-syncer testing
firmware-syncer-env-clean:
	helm rollback hollow-sandbox
	./scripts/minio-dns-setup.sh clear

## create a firmware-syncer job
firmware-syncer-job:
	helm template syncer . --set syncer.enable_job=true | kubectl apply -f - -l app=syncer-job

## remove the firmware-syncer job
firmware-syncer-job-clean:
	helm template syncer . --set syncer.enable_job=true | kubectl delete -f - -l app=syncer-job

## connect to crdb with psql (requires port-forward-crdb)
psql-crdb: kubectl-ctx-kind
	psql -d "postgresql://root@localhost:26257/defaultdb?sslmode=disable"

## purge nats app and storage pvcs
clean-nats:
	kubectl delete statefulsets.apps nats && kubectl delete pvc nats-js-pvc-nats-0 nats-jwt-pvc-nats-0

## set kube ctx to kind cluster
kubectl-ctx-kind:
	export KUBECONFIG=~/.kube/config_kind
	kubectl config use-context kind-kind

# https://gist.github.com/prwhite/8168133
# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

TARGET_MAX_CHAR_NUM=32
## Show help
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
