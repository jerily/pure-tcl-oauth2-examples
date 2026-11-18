# SPDX-License-Identifier: MIT
package require pure-tcl-oauth2-core
package require twebserver
namespace eval ::demo {variable browsers {}; variable authorizations {}; variable origin; variable cookieName}
proc ::demo::html {text} {string map {& &amp; < &lt; > &gt; \" &quot; ' &#39;} $text}
proc ::demo::page {body} {
    dict create statusCode 200 headers {Content-Type {text/html; charset=utf-8} Cache-Control no-store Referrer-Policy same-origin \
        Content-Security-Policy {default-src 'none'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'}} body "<!doctype html><title>OAuth2 example</title><main>$body</main>"
}
proc ::demo::header {request name} {
    dict for {key value} [dict get $request headers] {if {[string equal -nocase $key $name]} {return $value}}
    return {}
}
proc ::demo::browser {request} {
    variable browsers; variable cookieName
    foreach pair [split [header $request cookie] {;}] {
        set pair [string trim $pair]
        if {[string match $cookieName=* $pair]} {
            set id [string range $pair [expr {[string length $cookieName]+1}] end]
            if {[dict exists $browsers $id] && [dict get $browsers $id expires] > [clock seconds]} {return $id}
        }
    }
    set now [clock seconds]
    dict for {id data} $browsers {if {[dict get $data expires] <= $now} {dict unset browsers $id}}
    set id [::oauth2::core::random]
    dict set browsers $id [dict create expires [expr {$now+600}] csrf [::oauth2::core::random]]
    return $id
}
proc ::demo::form {request} {
    if {[dict get $request method] ne "POST" || [string tolower [lindex [split [header $request content-type] {;}] 0]] ne "application/x-www-form-urlencoded"} {error "A form POST is required"}
    ::oauth2::core::form_decode [dict get $request body]
}
proc ::demo::csrf {request fields id} {
    variable browsers; variable origin
    if {[header $request origin] ni [list {} $origin] || ![dict exists $fields csrf] ||
        ![::oauth2::core::equal [dict get $fields csrf] [dict get $browsers $id csrf]]} {error "Invalid CSRF token"}
}
proc ::demo::redirect {url} {dict create statusCode 302 headers [dict create Location $url Cache-Control no-store Referrer-Policy no-referrer] body {}}
proc ::demo::process {context request} {
    variable handler
    dict set request method [dict get $request httpMethod]
    if {[dict exists $request isBase64Encoded] && [dict get $request isBase64Encoded]} {dict set request body [binary decode base64 -strict [dict get $request body]]}
    if {[catch {{*}$handler $request} response]} {set response [dict create statusCode 400 headers {Content-Type text/plain Cache-Control no-store} body {Request rejected. Return to the example home page.}]}
    ::twebserver::return_response [dict get $context conn] $response
}
# Retain the common script path after sourcing has completed.
set ::demo::commonPath [info script]
proc ::demo::start {port script handlerCommand} {
    variable commonPath
    package require twebserver
    set init [list set auto_path $::auto_path]
    append init \n [list source $commonPath] \n $script \n [list set ::demo::handler $handlerCommand]
    set server [::twebserver::create_server {} ::demo::process $init]
    ::twebserver::listen_server -http -host 127.0.0.1 -num_threads 1 $server $port
    puts "Open http://localhost:$port/ (loopback demo only)."
    ::twebserver::wait_signal
    ::twebserver::destroy_server $server
}
