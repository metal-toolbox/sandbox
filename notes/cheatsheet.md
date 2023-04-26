### NATS

The below commands run on the nats box

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

Consume an event as conditionorc
```
nats consumer sub --creds=/root/nsc/nkeys/creds/KO/controllers/conditionorc.creds -s nats://nats:4222
```
