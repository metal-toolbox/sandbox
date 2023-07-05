#!/bin/bash
set -ex

# see notes/oauth.md

## TODO:
## - add machine to machine Serverservice client for conditionorc
## - add machine to machine Serverservic client for flasher

domain="${OKTA_DOMAIN}"
token="${OKTA_TOKEN}"

audience="http://localhost:8000"
callback="http://localhost:18000/identity/callback"


# create authorization server
out=$(curl -X POST \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	-H "Authorization: SSWS ${token}" \
	-d '{
  "name": "Sandbox authorization server",
  "description": "Sandbox authorization server",
  "audiences": [
    "'${audience}'"
  ]
}' "https://${domain}/api/v1/authorizationServers")

authorizationServerID=$(echo $out | jq -rM .id)
issuer=$(echo $out | jq -rM .issuer)
jwksURI="https://${domain}/oauth2/${authorizationServerID}/v1/keys"

out=$(curl -X POST \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	-H "Authorization: SSWS ${token}" \
	-d '{
  "type": "OAUTH_AUTHORIZATION_POLICY",
  "status": "ACTIVE",
  "name": "Sandbox policy",
  "description": "Sandbox API access",
  "priority": 1,
  "conditions": {
    "clients": {
      "include": [
        "ALL_CLIENTS"
      ]
    }
  }
}' "https://${domain}/api/v1/authorizationServers/${authorizationServerID}/policies")

policyID=$(echo $out | jq -rM .id)

# create resource accesss rule
out=$(curl -X POST \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: SSWS ${token}" \
-d '{
    "type": "RESOURCE_ACCESS",
    "name": "Sandbox Access rule",
    "priority": 1,
    "conditions": {
      "people": {
        "groups": {
          "include": [
            "EVERYONE"
          ]
        }
      },
      "grantTypes": {
        "include": [
          "implicit",
          "client_credentials",
          "authorization_code",
          "password"
        ]
      },
      "scopes": {
        "include": [
          "*"
        ]
      }
    },
    "actions": {
      "token": {
        "accessTokenLifetimeMinutes": 60,
        "refreshTokenLifetimeMinutes": 0,
        "refreshTokenWindowMinutes": 10080
      }
    }
}' "https://${domain}/api/v1/authorizationServers/${authorizationServerID}/policies/${policyID}/rules")


# create serverservice scopes on the authorization server
serverservice_scopes="read:server-component-firmware-sets \
read:server-component-firmwares \
read:server \
read:server-component-types \
create:server-component-types \
update:server-component-types \
delete:server-component-types \
read:server:component \
update:server:component \
read:server:credentials \
read:server:attributes \
create:server:attributes \
update:server:attributes \
delete:server:attributes \
read:server:versioned-attributes \
create:server:versioned-attributes \
update:server:versioned-attributes \
delete:server:versioned-attributes \
create:server-component-firmwares \
read:server-component-firmwares \
update:server-component-firmwares \
delete:server-component-firmwares \
read:server-component-firmware-sets \
create:server-component-firmware-sets \
update:server-component-firmware-sets \
delete:server-component-firmware-sets"

for scope in ${serverservice_scopes};
do
  curl -X POST \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: SSWS ${token}" \
  -d '{
    "description": "'${scope}'",
    "name": "'${scope}'",
    "concent": "IMPLICIT"
  }' "https://${domain}/api/v1/authorizationServers/${authorizationServerID}/scopes"
done


# create conditions API scopes on the authorization server
conditions_scopes="read:server \
read:condition \
create:condition \
update:condition \
write:condition \
delete:condition"

for scope in ${conditions_scopes};
do
  curl -X POST \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: SSWS ${token}" \
  -d '{
    "description": "'${scope}'",
    "name": "'${scope}'",
    "concent": "IMPLICIT"
  }' "https://${domain}/api/v1/authorizationServers/${authorizationServerID}/scopes"
done

# create serverservice API client application
curl -X POST \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: SSWS ${token}" \
-d '{
    "name": "Serverservice API client",
    "label": "Serverservice API client",
    "signOnMode": "OPENID_CONNECT",
    "credentials": {
      "oauthClient": {
        "token_endpoint_auth_method": "none"
        }
        "pkce_required": true
    },
    "profile": {
        "label": "Serverservice API client"
        },
    "settings": {
      "oauthClient": {
        "client_uri": "",
        "logo_uri": "http://developer.okta.com/assets/images/logo-new.png",
        "redirect_uris": [
          "'${callback}'"
        ],
        "response_types": [
          "token",
          "id_token",
          "code"
        ],
        "grant_types": [
          "implicit",
          "authorization_code",
          "refresh_token"
        ],
        "application_type": "native"
      }
    }
}' "https://${domain}/api/v1/apps"

# create conditions API client application
curl -X POST \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: SSWS ${token}" \
-d '{
    "name": "Conditions API client",
    "label": "Conditions API client",
    "signOnMode": "OPENID_CONNECT",
    "credentials": {
      "oauthClient": {
        "token_endpoint_auth_method": "none"
        }
        "pkce_required": true
    },
    "profile": {
        "label": "Conditions API client"
        },
    "settings": {
      "oauthClient": {
        "client_uri": "",
        "logo_uri": "http://developer.okta.com/assets/images/logo-new.png",
        "redirect_uris": [
          "'${callback}'"
        ],
        "response_types": [
          "token",
          "id_token",
          "code"
        ],
        "grant_types": [
          "implicit",
          "authorization_code",
          "refresh_token"
        ],
        "application_type": "native"
      }
    }
}' "https://${domain}/api/v1/apps"


echo "All done..........."
echo "JWKS URI: ${jwksURI}"
echo "Audience: ${audience}"
echo "Issuer: ${issuer}"
echo "PKCE endpoint: ${callback}"