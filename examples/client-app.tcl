package require pure-tcl-oauth2-client
set ::demo::cookieName oauth2_client_demo
set ::demo::transactions [::oauth2::store::memory]
set ::demo::client [::oauth2::client::create {*}$::demo::clientOptions -transaction_store $::demo::transactions -allow_http true]
proc ::demo::client_handler {request} {
    variable client; variable browsers; variable cookieName; variable transactions
    $transactions prune [clock seconds]
    set id [browser $request]
    set path [dict get $request path]
    if {$path eq "/login"} {
        set fields [form $request]; csrf $request $fields $id
        return [redirect [dict get [$client start -browser_session $id -prompt select_account] authorization_url]]
    }
    if {$path eq "/callback" && [dict get $request method] eq "GET"} {
        set identity [$client callback [::oauth2::core::form_decode [dict get $request queryString]] -browser_session $id]
        # Discard provider tokens. Only keep verified identity in this example.
        set subject [dict get $identity subject]
        dict unset browsers $id
        set id [browser [dict create headers {}]]
        dict set browsers $id subject $subject
        set response [redirect /]
    } elseif {$path eq "/" && [dict get $request method] eq "GET"} {
        set body {<h1>OAuth2 client</h1>}
        if {[dict exists $browsers $id subject]} {append body "<p>Signed in as [html [dict get $browsers $id subject]].</p>"}
        append body "<form method=post action=/login><input type=hidden name=csrf value='[html [dict get $browsers $id csrf]]'><button>Continue to provider</button></form>"
        set response [page $body]
    } else {error "Unknown route"}
    dict set response headers Set-Cookie "$cookieName=$id; Path=/; HttpOnly; SameSite=Lax"
    return $response
}
