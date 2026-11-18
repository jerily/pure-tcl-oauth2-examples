# Run in one terminal, then local-client.tcl in another.
source [file join [file dirname [info script]] common.tcl]
::demo::start 8090 {
    package require pure-tcl-oauth2-server
    set ::demo::origin http://localhost:8090
    set ::demo::cookieName oauth2_provider_demo
    set ::demo::store [::oauth2::store::memory]
    set ::demo::signer [::tink::register_keyset [::tink::jwt::create_private_keyset RS256_2048_F4]]
    set ::demo::server [::oauth2::server::create -issuer $::demo::origin -allow_http true -store $::demo::store -signing_key $::demo::signer]
    $::demo::server register_client demo -redirect_uris {http://localhost:8091/callback} -scope {openid email profile} -audiences demo-api
    proc ::demo::provider {request} {
        variable server; variable browsers; variable cookieName; variable authorizations; variable store
        $store prune [clock seconds]
        set path [dict get $request path]; set method [dict get $request method]
        if {$method eq "GET"} {
            switch $path {
                /.well-known/openid-configuration {return [::oauth2::core::response [$server metadata]]}
                /jwks {return [::oauth2::core::response [$server jwks]]}
                /userinfo {return [::oauth2::core::response [$server userinfo [::oauth2::core::bearer [header $request authorization]]]]}
                /authorize {
                    set id [browser $request]
                    set validated [$server authorize_validate [::oauth2::core::form_decode [dict get $request queryString]]]
                    set requestId [dict get $validated request_id]
                    dict set authorizations $requestId $id
                    set body "<h1>Local authorization server</h1><p>This demonstration signs in as demo-user. A real host supplies its own login and consent UI.</p><p>Client: [html [dict get $validated client_id]]; scopes: [html [dict get $validated scope]]</p>"
                    append body "<form method=post action=/consent><input type=hidden name=csrf value='[html [dict get $browsers $id csrf]]'><input type=hidden name=request_id value='[html $requestId]'><button name=consent value=yes>Allow as demo-user</button><button name=consent value=no>Deny</button></form>"
                    set response [page $body]
                    dict set response headers Set-Cookie "$cookieName=$id; Path=/; HttpOnly; SameSite=Lax"
                    return $response
                }
                / {return [page {<h1>Local OAuth2 provider</h1><p>Start the client at <a href="http://localhost:8091/">localhost:8091</a>.</p>}]}
            }
        }
        if {$method eq "POST" && $path in {/token /revoke /introspect}} {
            form $request
            return [$server endpoint [string trimleft $path /] [dict get $request body] [header $request authorization]]
        }
        if {$path eq "/consent"} {
            set fields [form $request]; set id [browser $request]
            csrf $request $fields $id
            set requestId [dict get $fields request_id]
            if {![dict exists $authorizations $requestId] || [dict get $authorizations $requestId] ne $id} {error "Invalid consent transaction"}
            dict unset authorizations $requestId
            return [$server authorize_complete $requestId demo-user -consent [expr {[dict get $fields consent] eq "yes"}] -claims {email {S demo@example.com} email_verified {BOOL 1} name {S Demo}}]
        }
        error "Unknown route"
    }
} ::demo::provider
