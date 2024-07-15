.DEFAULT_GOAL := help

CONDITION_ORC_PORT=9001
ALLOY_PORT=9091
FLEETDB_PORT=8000
CRDB_UI_PORT=8081
CRDB_PORT=26257
CHAOS_DASH_PORT=2333
JAEGER_DASH_PORT=16686
MINIO_PORT=9000

ifneq (,$(wildcard .local-values.yaml))
	OVERRIDE_VALUES_YAML=-f .local-values.yaml
else
	OVERRIDE_VALUES_YAML=
endif

## install helm chart for the sandbox env with fleetdb(default)
install: kubectl-ctx-kind
	cp ./scripts/nats-bootstrap/values-nats.yaml.tmpl values-nats.yaml
	./scripts/makefile/generate-chart.sh
	helm dependency update
	helm install hollow-sandbox . -f values.yaml -f values-nats.yaml ${OVERRIDE_VALUES_YAML}
	kubectl get pod
	./scripts/nats-bootstrap/boostrap.sh

## upgrade helm chart for the sandbox environment
upgrade: kubectl-ctx-kind
	helm dependency update
	helm upgrade hollow-sandbox . -f values.yaml -f values-nats.yaml ${OVERRIDE_VALUES_YAML}

## uninstall helm chart
clean: kubectl-ctx-kind
	helm uninstall hollow-sandbox
	rm values-nats.yaml
	./scripts/wait-clean.sh

## port forward condition orchestrator API  (runs in foreground)
port-forward-conditionorc-api: kubectl-ctx-kind
	kubectl port-forward deployment/conditionorc-api ${CONDITION_ORC_PORT}:${CONDITION_ORC_PORT}

## port forward condition Alloy pprof endpoint  (runs in foreground)
port-forward-alloy-pprof: kubectl-ctx-kind
	kubectl port-forward deployment/alloy ${ALLOY_PORT}:${ALLOY_PORT}

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

port-forward-crdb-ui:
	kubectl port-forward deployment/fleetdb-crdb --address 0.0.0.0  ${CRDB_UI_PORT}:8080

## port forward all endpoints (runs in the background)
port-all-with-lan:
	kubectl port-forward deployment/conditionorc-api --address 0.0.0.0 ${CONDITION_ORC_PORT}:${CONDITION_ORC_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/alloy --address 0.0.0.0 ${ALLOY_PORT}:${ALLOY_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/crdb --address 0.0.0.0 ${CRDB_PORT}:${CRDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/fleetdb --address 0.0.0.0 ${FLEETDB_PORT}:${FLEETDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/fleetdb-crdb --address 0.0.0.0 ${CRDB_PORT}:${CRDB_PORT} > /dev/null 2>&1 &
	kubectl port-forward service/chaos-dashboard --address 0.0.0.0 ${CHAOS_DASH_PORT}:${CHAOS_DASH_PORT} > /dev/null 2>&1 &
	kubectl port-forward service/jaeger --address 0.0.0.0 ${JAEGER_DASH_PORT}:${JAEGER_DASH_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/minio --address 0.0.0.0 ${MINIO_PORT}:${MINIO_PORT} > /dev/null 2>&1

port-all:
	kubectl port-forward deployment/conditionorc-api ${CONDITION_ORC_PORT}:${CONDITION_ORC_PORT} > /dev/null 2>&1 &
	kubectl port-forward deployment/alloy ${ALLOY_PORT}:${ALLOY_PORT} > /dev/null 2>&1 &
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

## Change service to local service instead of upstream. DIR is optional, defaults to "../".
## Example: `make fleet-scheduler-local ../services/fleet-scheduler` will tell sandbox to use ../services/fleet-scheduler instead of the upstream
## Note: Use `make fleet-scheduler-upstream` to revert this process
%-local:
	$(eval DIR ?= ../)
	./scripts/makefile/set-service-to-local.sh $(subst -local,,$@) ${DIR}

## Change service to upstream service instead of local.
## Example: `make fleet-scheduler-upstream` will tell sandbox to use the upstream (https://metal-toolbox.github.io/fleet-scheduler) fleet-scheduler.
%-upstream:
	yq -i "del(.localrepos.[] | select(.name == \"$(subst -upstream,,$@)\"))" .local-values.yaml

## Get some meta info about a service.
## Example: `make fleet-scheduler-info`
%-info:
	./scripts/makefile/get-service-info.sh $(subst -info,,$@)

## Show help
help:
	./scripts/makefile/help.awk ${MAKEFILE_LIST}