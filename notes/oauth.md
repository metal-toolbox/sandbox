
# Integrate Okta based OIDC Auth

These are notes to setup OIDC Auth for Serverservice, Conditionorc API services
along with the mctl client.

## Auth flow with PKCE

The mctl app does not store any secret token and OIDC service (Okta)
is configured with an Authorization server that does [PKCE](https://datatracker.ietf.org/doc/html/rfc7636)
based OIDC auth flow for clients connecting our service(s).


For this example, we're running a command using `mctl` to list firmware in `Serverservice`.

- User runs `mctl list firmware`
- `mctl` generates a [Code verifier, Code challenge](https://datatracker.ietf.org/doc/html/rfc7636#section-4.1)
- The users machine is expected to have a browser session logged into Okta.
- `mctl` spawns a browser window on the users machine and connects to the OIDC provider with the Code verifier, challenge.
- The OIDC provider redirects to the configured callback URL with the authorization code.
- The callback URL is configured in Okta on the Authorization server and is along the lines of `localhost:port/callback`.
- `mctl` hosts the callback endpoint, it receives the authorization code.
- `mctl` exchanges the authorization code, code verifier for an Access Token.
- `mctl` requests `Serverservice` at the `/api/v1/server-component-firmwares` with a header in the format `Authorization: bearer <AccessToken>`.
- The [ginjwt middleware](https://github.com/metal-toolbox/hollow-toolbox/blob/c3044c6809ac4fddb65a1c8e237ca8f2b6f0bccd/ginjwt/jwt.go#L129) in `Serverservice` validates the key ID in the access token matches the one returned in the configured JWKS URI.
- The ginjwt middleware [validates scopes](https://github.com/metal-toolbox/hollow-toolbox/blob/c3044c6809ac4fddb65a1c8e237ca8f2b6f0bccd/ginjwt/jwt.go#L217) and any claims present in the token.
- Now the firmware data is returned to the client.

## Setting up OIDC Auth flow in Okta for Serverservice, Conditionorc.

To begin create a developer account with Okta and figure out the Okta domain for your account,
it'll be in the form `dev-74418858.okta.com` and is listed on the top right.

Create an access token from https://<okta domain>/admin/access/api/tokens.

Follow the steps below to run the script to setup the authorization services and policies.

For an overview of what the script does, read below.

### Setup
 - Add an OIDC app for Serverservice, Conditionorc as Native.
  - Make sure the configured callback URL is the same as the one expected by mctl.
  - Ensure Refresh token, Token exchange is enabled.
  - Ensure PKCE is enabled.
  - Ensure Client auth is set to none.
 - Add a machine to machine based app for conditionorc <-> serverservice api.
 - Add a machine to machine based app for flasher <-> serverservice api.
 - Add an Authorization server.
 - Add an access policy.
 - Setup scopes.

### Run script
 ```
 OKTA_DOMAIN="dev-74418858-admin.okta.com" \
 OKTA_TOKEN="00yYgnral5YXXXXYBVvcU10lqO0h_7Q3yZh0cEFb6i" \
    ./scripts/okta-oidc/setup.sh
 ```

 ## Troubleshooting

- The issuer, JWKS URI configuration can be fetched from `https://<okta domain>/oauth2/<authorization server ID>/.well-known/oauth-authorization-server`.
- Break down the troubleshooting into multiple steps, by stepping through the auth flow example provided above.
- Verify which service is returning the error being seen.
- The Okta dashboard provides a system log and can be used to debug OIDC related errors.
- If Serverservice/Conditionorc returns the error `invalid token signing key`, fetch the JWKS key from the JWKS URI,
 compare the `kid` value with the one in the Access token. The access token can be dumped from mctl and decoded here at https://token.dev/.
