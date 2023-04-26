#!/bin/sh

# run firmware update on asset
curl -Lv -X POST -d '{"exclusive": true, "parameters": {"assetID": "ede81024-f62a-4288-8730-3fab8cceab78", "firmwareSetID": "9d70c28c-5f65-4088-b014-205c54ad4ac7"}}' \
	localhost:9001/api/v1/servers/ede81024-f62a-4288-8730-3fab8cceab78/condition/firmwareInstallOutofband

# check status
curl -Lv localhost:9001/api/v1/servers/ed33d13d-bb56-42d8-aff4-594d4acbcbbf/condition/firmwareInstallOutofband
