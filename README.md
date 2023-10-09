## k8s helm charts for the hollow sandbox.

This chart deploys the various metal-toolbox/hollow services in docker KIND for development and testing.

 - [Serverservice](https://github.com/metal-toolbox/hollow-serverservice) with the CrDB backend.
 - [Conditionorc](https://github.com/metal-toolbox/conditionorc)
 - [Alloy](https://github.com/metal-toolbox/alloy/tree/v2) (v2 branch)
 - [Flasher](https://github.com/metal-toolbox/flasher/)
 - NATS Jetstream and K/V
 - Chaos mesh

The [mctl](https://github.com/metal-toolbox/mctl/) utility can be used to interact with the various services running in the sandbox.

To understand more about the firmware install and how these services interact, check out the [firmware install architecture](https://github.com/metal-toolbox/architecture/blob/main/firmware-install-service.md) doc.

### Prerequisites

- Install docker KIND
- Setup a local KIND cluster with a registry using the script here: https://kind.sigs.k8s.io/docs/user/local-registry/
- Export `KUBECONFIG=~/.kube/config_kind`
- Docker images for Serverservice, Conditionorc, Alloy
- Install [mctl](https://github.com/metal-toolbox/mctl#getting-started) and use the configuration from [here](https://github.com/metal-toolbox/sandbox/tree/main/scripts/mctl)

### 1. Build docker images and push to local registry

Clone each of the repositories and run `make push-image-devel`

 - [Serverservice](https://github.com/metal-toolbox/hollow-serverservice)
 - [Conditionorc](https://github.com/metal-toolbox/conditionorc)
 - [Alloy](https://github.com/metal-toolbox/alloy/tree/v2) (v2 branch)
 - [Flasher](https://github.com/metal-toolbox/flasher/)

This will build and push the container images to the local container registry.


### 2. Deploy helm chart

Deploys the helm chart and bootstrap the NATS Jetstream, K/V store.

```sh
make install
```

### 3. Import a server

To run set [conditions](https://github.com/metal-toolbox/architecture/blob/main/firmware-install-service.md#conditions) on a server, they need to be enlisted in the sandbox `Serverservice`.

Note: this assumes the KIND environment on your machine can connect to server BMC IPs.

- Make sure the `Serverservice` and `CrDB` pods are running.
- run `make port-forward-hss`.
- Add a server using the helper script.

```sh
go run scripts/serverservice/add-server.go \
        -server-id edeff024-f62a-4288-8730-3fab8cceab78 \
        -facility fr9 \
        -bmc-addr 127.0.0.1 \
        -bmc-user bar \
        -bmc-pass foo
```

### 4. Collect information on the server

This collects the current firmware, health information and BIOS configuration data for a server.

```sh
mctl collect inventory --server edeff024-f62a-4288-8730-3fab8cceab78
```

Inventory collection status can be checked with,

```sh
mctl collect status --server edeff024-f62a-4288-8730-3fab8cceab78
```

### 5. Import firmware definitions (optional)

Note: replace `ARTIFACTS_ENDPOINT` in [firmwares.json](./scripts/mctl/firmwares.json) with endpoint serving the firmware files.

Import firmware defs from sample file using `mctl`.

```sh
mctl create  firmware --from-file ./scripts/mctl/firmwares.json
```

### 6. Create a firmware set (optional)

List the firmware using `mctl list firmware` and create a set that can be applied to a server.

```sh
mctl create firmware-set --firmware-uuids 5e574c96-6ba4-4078-9650-c52a64cc8cba,a7e86975-11a4-433d-9170-af53fcfc79bd \
                         --labels vendor=dell,model=r6515,latest=true \
                         --name r6515
```

### 7. Set a `firmwareInstall` condition on a server (optional)

With the server added, you can now get flasher to set a `firmwareInstall` condition,

```sh
make port-forward-conditionorc-api
```

```sh
mctl install firmware-set --server edeff024-f62a-4288-8730-3fab8cceab78
```

Check condition status

```sh
mctl install status --server edeff024-f62a-4288-8730-3fab8cceab78
```

### Upgrade/uninstall helm chart.

To upgrade the helm install after changes to the templates,

```
make upgrade
```

To uninstall the helm chart

```
make clean
```

## NATs Jetstream setup

The chart configures a NATS Jetstream that Serverservice, Orchestrator and the
controllers sends messages on, the NATS Jetstream configuration is specified in [values.yaml](values.yaml).

Check out the [cheatsheet](notes/cheatsheet.md) to validate the Jetstream setup.

## Chaos mesh (optional)

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
  install              install helm chart for the sandbox env
  upgrade              upgrade helm chart for the sandbox environment
  clean                uninstall helm chart
  port-forward-conditionorc-api port forward condition orchestrator API  (runs in foreground)
  port-forward-alloy-pprof port forward condition Alloy pprof endpoint  (runs in foreground)
  port-forward-hss     port forward hollow server service port (runs in foreground)
  port-forward-crdb    port forward crdb service port (runs in foreground)
  port-forward-chaos-dash port forward chaos-mesh dashboard (runs in foreground)
  port-forward-jaeger-dash port forward jaeger frontend
  psql-crdb            connect to crdb with psql (requires port-forward-crdb)
  clean-nats           purge nats app and storage pvcs
  kubectl-ctx-kind     set kube ctx to kind cluster
  help                 Show help
```
