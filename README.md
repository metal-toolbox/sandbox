## k8s helm charts for the hollow sandbox.

This chart deploys multiple metal-toolbox/hollow services in docker KIND for +development and testing.

 - Serverservice and crDB
 - Conditionorc
 - Alloy
 - NATS Jetstream
 - Chaos mesh

### Prerequisites

- Install docker KIND
- Setup a local KIND cluster with a registry using the script here: https://kind.sigs.k8s.io/docs/user/local-registry/
- Export `KUBECONFIG=~/.kube/config_kind`
- Docker images for Serverservice, Conditionorc, Alloy

### Build docker image and push to local registry

1. In the serverservice repository, build the docker image,

```
export GIT_TAG="localhost:5001/serverservice:latest" && \
    GOOS=linux GOARCH=amd64 go build -o serverservice && \
    docker build -t "${GIT_TAG}" -f Dockerfile . && \
    docker push localhost:5001/serverservice:latest && kind load docker-image "${GIT_TAG}"
```

2. In the Alloy, Conditionorc, Flasher git repositories run,
```
make build-image-devel
```

### Deploy helm chart.

- Run `make local-devel`


4. Finally run helm upgrade
```
make local-devel
```

5. To upgrade the install, run

```
make local-devel-upgrade
```

## NATs Jetstream setup

The chart configures a NATS Jetstream that Serverservice, Orchestrator and the
controllers sends messages on, the NATS Jetstream configuration is specified in [values.yaml](values.yaml).

The services auth in the NATS Jetstream using JWT, to have this properly setup
on a new sandbox install or update, follow the steps in [nats-bootstrap](./scripts/nats-bootstrap/README.md).

Check out the [cheatsheet](cheatsheet.md) to validate the Jetstream setup.

## Chaos mesh

The utility exposes a cool dashboard to run chaos experiments like dropping packets
from one app to another or such.


Install chaos mesh
```
helm install chaos-mesh  chaos-mesh/chaos-mesh -n=default --version 2.5.1 -f values.yaml
```


forward the dashboard port and run an experiment ! `http://localhost:2333/experiments`
```
make port-forward-chaos-dash
```

Uninstall chaos mesh
```
helm delete  chaos-mesh -n=default
```

### Check out make help for a list of available commands.

```
❯ make

Usage:
  make <target>

Targets:
  local-devel          install helm chart for the sandbox env
  local-devel-upgrade  upgrade helm chart for the sandbox environment
  port-forward-conditionorc-api port forward condition orchestrator API  (runs in foreground)
  port-forward-alloy-pprof port forward condition Alloy pprof endpoint  (runs in foreground)
  port-forward-hss     port forward hollow server service port (runs in foreground)
  port-forward-crdb    port forward crdb service port (runs in foreground)
  port-forward-chaos-dash port forward chaos-mesh dashboard (runs in foreground)
  psql-crdb            connect to crdb with psql (requires port-forward-crdb)
  clean-nats           purge nats app and storage pvcs
  kubectl-ctx-kind     set kube ctx to kind cluster
  help                 Show help
```
