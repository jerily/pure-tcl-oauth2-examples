# pure-tcl-oauth2-examples

Runnable examples for the separate core, client and server packages. Requires
Tcl 9.1 and the versions listed in `ttrek.json`. Install native dependencies,
then each OAuth package with CMake as described in the core README. Find an
installed example with `::oauth2::examples::path` after requiring this package.

## Local provider and client

Run in two terminals with the same `TCLLIBPATH`:

```sh
tclsh9.1 examples/local-server.tcl
tclsh9.1 examples/local-client.tcl
```

Open **http://localhost:8091/**, continue to the provider, and grant consent as
`demo-user`. The provider listens on port 8090 and the client on 8091. Both bind
only to loopback. The provider's identity is deliberately a demo; a real host
supplies authentication and consent. One worker uses memory storage and new keys
on every restart. Production applications use SQL and persistent keys.

With both examples running, `python3 tests/local-flow.py` exercises real HTTP
discovery, consent, PKCE, token exchange, JWKS, signature verification and replay
rejection. It never accesses Google. Stop the demos with Ctrl-C.

## Google Login

1. In Google Cloud's **Google Auth Platform**, configure branding, audience and
   consent. For an external application in testing, add your test users.
2. Create an OAuth client of type **Web application**. For the standalone example,
   register the exact redirect `http://localhost:8091/callback`. Scheme, hostname,
   port, path and trailing slash must match. Use `localhost` consistently.
3. Copy `examples/google-config.json` to a private file, replace both fake values
   with that client's credentials, restrict file access, and run:

```sh
tclsh9.1 examples/google-login.tcl /private/google-config.json
```

Open http://localhost:8091/. The client requests `openid email profile`, uses
state, nonce and PKCE, validates Google's signed ID token, and retains only the
verified subject in its browser session. The sample does not request offline
access or store Google API tokens. A client secret never belongs in browser code.

For production use your HTTPS callback, persistent transaction storage and keys,
secure cookies, explicit account linking and your site's session lifecycle.
`redirect_uri_mismatch` means the registered callback differs; `invalid_client`
usually means credentials belong to another OAuth client or were not configured.
An access-denied response may mean consent or testing-user eligibility needs work.
Never weaken token checks to work around configuration errors.

Google's authoritative setup and token-validation references:
[OpenID Connect](https://developers.google.com/identity/openid-connect/openid-connect)
and [web-server OAuth](https://developers.google.com/identity/protocols/oauth2/web-server).

## web-user integration

`examples/web-user-google.tcl` is a host adapter. Before mounting, set `ENV` to
LOCAL or PROD, open the appropriate SQL connection, explicitly call
`::web::user::initdb $connection`, and obtain persistent AEAD/MAC keyset JSON.
Call `mount_google_accounts` with those keysets, an email hash salt, private Google
credentials and the exact site origin. In this integration the callback is
`$origin/user/google/callback`, **not** the standalone example's `/callback`.
Credentials go through `-secret_config`; public properties never receive them.
After removing routes call `::web::user::release $mount`, then close the host-owned connection. See web-user's Google Login documentation for linking,
passwordless account management and local MFA behavior.
