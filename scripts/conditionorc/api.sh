#!/bin/sh

# collect inventory on asset
curl -X POST -d '{"foo": "bar"}' localhost:9001/api/v1/servers/01f26e67-aecf-4b83-8944-39667cf1834b/condition/inventoryOutofband

# check status
localhost:9001/api/v1/servers/ed33d13d-bb56-42d8-aff4-594d4acbcbbf/condition/inventoryOutofband
