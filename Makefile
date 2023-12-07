.DEFAULT_GOAL := help

## install helm chart for the sandbox env
install: kubectl-ctx-kind
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
	kubectl port-forward deployment/conditionorc-api 9001:9001

## port forward condition Alloy pprof endpoint  (runs in foreground)
port-forward-alloy-pprof: kubectl-ctx-kind
	kubectl port-forward deployment/alloy 9091:9091

## port forward hollow server service port (runs in foreground)
port-forward-hss: kubectl-ctx-kind
	kubectl port-forward deployment/serverservice 8000:8000

## port forward crdb service port (runs in foreground)
port-forward-crdb: kubectl-ctx-kind
	kubectl port-forward deployment/crdb 26257:26257

## port forward chaos-mesh dashboard (runs in foreground)
port-forward-chaos-dash: kubectl-ctx-kind
	kubectl port-forward  service/chaos-dashboard 2333:2333

## port forward jaeger frontend
port-forward-jaeger-dash:
	kubectl port-forward  service/jaeger 16686:16686

## port forward to the minio S3 port
port-forward-minio:
	kubectl port-forward deployment/minio 9000

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

#
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


TARGET_MAX_CHAR_NUM=20
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
