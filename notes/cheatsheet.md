### NATS

The below commands run on the nats box.

### helper scripts

To purge all active conditions from the KV and Jetstream, checkout the
[nats-js-kv-clean.sh](scripts/scripts/nats-js-kv-clean.sh) script.

### snippets
Make sure the nats account creds are available in nats box
```
source scripts/nats-bootstrap/functions.sh && restore_accounts
```

spawn shell in nats-box
```
kubectl exec -ti deployments/nats-box /bin/sh
```

check jetstream service is enabled, serverservice account can auth.
```
nats account info --creds=/root/nsc/nkeys/creds/KO/serverservice/serverservice.creds -s nats://nats:4222
```

list nats streams - once serverservice connects, it'll create the stream
```
nats stream ls --creds=/root/nsc/nkeys/creds/KO/serverservice/serverservice.creds -s nats://nats:4222
╭────────────────────────────────────────────────────────────────────────────────────╮
│                                      Streams                                       │
├───────────────┬─────────────┬─────────────────────┬──────────┬──────┬──────────────┤
│ Name          │ Description │ Created             │ Messages │ Size │ Last Message │
├───────────────┼─────────────┼─────────────────────┼──────────┼──────┼──────────────┤
│ serverservice │             │ 2023-02-08 13:48:05 │ 0        │ 0 B  │ never        |
╰───────────────┴─────────────┴─────────────────────┴──────────┴──────┴──────────────╯
```

Consume an event as conditionorc
```
nats consumer sub --creds=/root/nsc/nkeys/creds/KO/controllers/conditionorc.creds -s nats://nats:4222
```

list keys in statusKV buckets
```
nats -s nats://nats:4222 --creds=nsc/nkeys/creds/KO/controllers/alloy.creds kv ls firmwareInstall -v  --display-value
nats -s nats://nats:4222 --creds=nsc/nkeys/creds/KO/controllers/alloy.creds kv ls inventory -v  --display-value
```

consume an event as alloy
```
nats -s nats://nats:4222 --creds=nsc/nkeys/creds/KO/controllers/alloy.creds consumer next controllers sandbox-alloy
```

view stream message without pop
```
~ # nats -s nats://nats:4222 --creds=nsc/nkeys/creds/KO/controllers/alloy.creds stream get
? Select a Stream controllers
? Message Sequence to retrieve -1
? Subject to retrieve last message for com.hollow.sh.controllers.commands.sandbox.servers.firmwareInstallInband.ede81024-f62a-4288-8730-3fab8cceab78
```


purge message from stream
```
~ # nats -s nats://nats:4222 --creds=nsc/nkeys/creds/KO/controllers/alloy.creds stream rmm
? Select a Stream controllers
? Message Sequence to remove 59
? Really remove message 59 from Stream controllers Yes
```
