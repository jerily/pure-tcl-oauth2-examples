# SPDX-License-Identifier: MIT
namespace eval ::oauth2::examples {variable root [file dirname [file dirname [info script]]]}
proc ::oauth2::examples::path {name} {
    variable root
    if {$name ni {local-server.tcl local-client.tcl google-login.tcl web-user-google.tcl google-config.json}} {error "Unknown example"}
    file join $root examples $name
}
package provide pure-tcl-oauth2-examples 0.1.0
