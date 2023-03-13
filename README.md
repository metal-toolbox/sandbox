## k8s helm charts for the hollow sandbox.

This deploys multiple applications in KIND for

 - Serverservice and crDB
 - Conditionorc
 - Alloy
 - Chaos mesh

### Prerequisites

- Install docker KIND
- Setup a local KIND cluster with a registry using the script here: https://kind.sigs.k8s.io/docs/user/local-registry/
- Export `KUBECONFIG=~/.kube/config_kind`
- Docker images for Serverservice, Conditionorc, Alloy

### Build docker image and push to local registry

1. In the serverservice repository, build the docker image,

```
export GIT_TAG="localhost:5000/serverservice:latest" && \
    GOOS=linux GOARCH=amd64 go build -o serverservice && \
    docker build -t "${GIT_TAG}" -f Dockerfile . && \
    docker push localhost:5000/serverservice:latest && kind load docker-image "${GIT_TAG}"
```

2. In the Alloy git repository run,
```
make build-image-devel
```

3. In the Conditionorc git repository run,
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

## NATs setup

The chart configures a NATS Jetstream that serverservice sends messages on,
for the list of accounts configured check out [values.yaml](values.yaml).

Messages sent from Serverservice are recieved by `conditionorc` which then forwards them to `alloy` to execute.

Also check out the [cheatsheet](cheatsheet.md) to validate the Jetstream setup.

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
  port-forward-hss     port forward hollow server service port (runs in foreground)
  port-forward-crdb    port forward crdb service port (runs in foreground)
  port-forward-chaos-dash port forward chaos-mesh dashboard (runs in foreground)
  psql-crdb            connect to crdb with psql (requires port-forward-crdb)
  kubectl-ctx-kind     set kube ctx to kind cluster
  help                 Show help
```
