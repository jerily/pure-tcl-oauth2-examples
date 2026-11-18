set directory [file dirname [info script]]
source [file join $directory common.tcl]
set init {set ::demo::origin http://localhost:8091
set ::demo::clientOptions {-issuer http://localhost:8090 -client_id demo -auth_method none -redirect_uri http://localhost:8091/callback}}
append init \n [list source [file join $directory client-app.tcl]]
::demo::start 8091 $init ::demo::client_handler
