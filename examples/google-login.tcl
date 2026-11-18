# Pass a private JSON configuration file; the checked-in example uses fake values.
set directory [file dirname [info script]]
source [file join $directory common.tcl]
if {[llength $argv] != 1} {error "Usage: tclsh9.1 google-login.tcl /path/to/google-config.json"}
set file [open [lindex $argv 0] r]
try {set settings [::oauth2::core::json [read $file]]} finally {close $file}
set options [list -provider google -client_id [::oauth2::core::claim_string $settings client_id] \
    -client_secret [::oauth2::core::claim_string $settings client_secret] -redirect_uri http://localhost:8091/callback]
set init [list set ::demo::clientOptions $options]
append init \n {set ::demo::origin http://localhost:8091} \n [list source [file join $directory client-app.tcl]]
::demo::start 8091 $init ::demo::client_handler
