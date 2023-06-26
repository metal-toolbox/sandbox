- dex example app works - scripts/dex
- TODO: Use k8s templates from below link, instead of ` helm install --generate-name --wait dex/dex`
 - https://github.com/dexidp/dex/blob/master/examples/k8s/dex.yaml
- Figure out how scopes are to be configured, if at all
- mctl configuration used
```
---
serverservice_endpoint: http://localhost:8000
oidc_issuer_endpoint: http://0.0.0.0:5556/dex
oidc_audience: https://localhost:8000
oidc_client_id: mctl
#disable_oauth: true
conditions_endpoint: http://localhost:9001
```
- TODO: have mctl read scopes from configuration
- TODO: figure out errors
```
{"level":"error","msg":"Failed to parse authorization request: Missing required
scope(s) [\"openid\"].","time":"2023-06-26T09:09:03Z"}
{"level":"info","msg":"missing client_secret on token request for client:
mctl","time":"2023-06-26T09:09:03Z"}
{"level":"info","msg":"missing client_secret on token request for client:
mctl","time":"2023-06-26T09:09:03Z"}
```
