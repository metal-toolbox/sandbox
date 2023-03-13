### NATS

The below commands run on the nats box

```
kubectl exec -ti nats-box-684d684c7c-qcq4m /bin/sh
```

check jetstream service is enabled, serverservice account can auth.
```
nats account info -s nats://serverservice:password@nats:4222
```

list nats streams - once serverservice connects, it'll create the stream
```
nats stream list -s nats://serverservice:password@nats:4222
╭────────────────────────────────────────────────────────────────────────────────────╮
│                                      Streams                                       │
├───────────────┬─────────────┬─────────────────────┬──────────┬──────┬──────────────┤
│ Name          │ Description │ Created             │ Messages │ Size │ Last Message │
├───────────────┼─────────────┼─────────────────────┼──────────┼──────┼──────────────┤
│ serverservice │             │ 2023-02-08 13:48:05 │ 0        │ 0 B  │ never        |
╰───────────────┴─────────────┴─────────────────────┴──────────┴──────┴──────────────╯
```

add a nats consumer
```
nats consumer add -s nats://serverservice:password@nats:4222

? Consumer name alloy
? Delivery target (empty for Pull Consumers)
? Start policy (all, new, last, subject, 1h, msg sequence) all
? Acknowledgement policy all
? Replay policy instant
? Filter Stream by subject (blank for all) com.hollow.sh.events.>
? Maximum Allowed Deliveries 1
? Maximum Acknowledgements Pending 0
? Deliver headers only without bodies No
? Add a Retry Backoff Policy No
? Select a Stream serverservice
Information for Consumer serverservice > alloy created 2023-02-08T14:50:12Z

Configuration:

        Durable Name: alloy
           Pull Mode: true
      Filter Subject: com.hollow.sh.events.>
      Deliver Policy: All
          Ack Policy: All
            Ack Wait: 30s
       Replay Policy: Instant
  Maximum Deliveries: 1
     Max Ack Pending: 1,000
   Max Waiting Pulls: 512

State:

...
```

List consumer report for alloy
```
~ # nats consumer report alloy -s nats://alloy:password@nats:4222
? Select a Stream serverservice
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                           Consumer report for serverservice with 1 consumers
│
├──────────┬──────┬────────────┬──────────┬─────────────┬─────────────┬─────────────┬───────────┬─────────┤
│ Consumer │ Mode │ Ack Policy │ Ack Wait │ Ack Pending │ Redelivered │
Unprocessed │ Ack Floor │ Cluster │
├──────────┼──────┼────────────┼──────────┼─────────────┼─────────────┼─────────────┼───────────┼─────────┤
│ alloy    │ Pull │ All        │ 30.00s   │ 0           │ 0           │ 0
│ 9         │ nats-0* │
╰──────────┴──────┴────────────┴──────────┴─────────────┴─────────────┴─────────────┴───────────┴─────────╯
```


Consumer an event
```
~ # nats consumer next serverservice alloy -s
nats://serverservice:password@nats:4222
[14:27:53] subj: com.hollow.sh.events.servers.create / tries: 1 / cons seq: 10
/ str seq: 10 / pending: 0

{"subject_urn":"urn:hollow:servers:099034d8-ac72-11ed-9c2d-3e22fbc86c7a","event_type":"create","additional_subjects":null,"actor_urn":"","source":"serverservice","timestamp":"2023-02-14T14:15:30.573844132Z","fields":null,"additional_data":{"data":{"id":"099034d8-ac72-11ed-9c2d-3e22fbc86c7a","name":"foobar","facility_code":"dc13","created_at":"2023-02-14T14:15:30.550580383Z","updated_at":"2023-02-14T14:15:30.550580383Z","deleted_at":null}}}

Acknowledged message
```
