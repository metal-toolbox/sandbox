### NATS auth terminology

- `Accounts` group users and Jetstream support is enabled/disabled at the account level NOTE: pub/sub permissions set at the Account level are not inherited by users of that account.
- `Signing keys` are associated with accounts and can be 'templated' with pub/sub permissions and have a `role` name set.
- `Users` are applications connecting to NATS to pub/sub, users can be assigned a `role`G.

## Nats accounts configuration

For a new instance of this sandbox, follow the steps listed in [restore](#restore).

To add accounts/users/change pub sub rights, follow the steps in [bootstrap](#bootstrap).

### restore

To restore previously setup accounts to a new NATS service,

1. copy over [nats-accounts.tar.gz](nats-accounts.tar.gz) into the `nats-box` pod

```
kubectl cp nats-accounts.tar.gz nats-box-684d684c7c-b48d6:/nats-accounts.tar.gz
```

2. extract the contents on the tarball
```
cd / && tar -xvzf nats-accounts.tar.gz
```

3. push the accounts to the NATS server
```
export NKEYS_PATH=/root/nsc/nkeys && \
export NSC_HOME=/root/nsc/accounts && \
nsc push --system-account SYS -u nats://nats:4222 -A
```

4. Optional - update the confimaps with the accounts

### bootstrap

The Operator account, System Account, Serverservice, Controller accounts
and users are setup through [nsc-bootstrap.sh](nsc-bootstrap.sh)

To setup these accounts/change credentials/pubsub rights,

1. make sure the nats-box pod is running, then copy over the boostrap script into the nats box pod.

```
kubectl cp nsc-bootstrap.sh nats-box-684d684c7c-ckqnc:/root/nsc-bootstrap.sh
```

2. run the bootstrap script and follow the prompts from the script.

```
chmod +x nsc-bootstrap.sh && ./nsc-bootstrap.sh
```

3. follow the prompts from the nsc-bootstrap.sh script to completion.

running the script and following the prompts will,
1. create the accounts, users
2. prompt to copy over the Operator, SYS, Resolver preload tokens into `values.yaml` and reload the helm chart, `nats` server pod.
3. create a tarball of the accounts so they can be downloaded and re-used.
4. the NATS creds files are printed so they can be copied into the configmaps for Alloy, Conditionorc, Serverservice.
