# Source after opening the database. Run initdb during maintenance.
# The mount registers its private keysets; the caller owns the connection.
package require web-user 0.6.0
proc mount_google_accounts {router connection aeadKeyset macKeyset emailSalt clientId clientSecret origin} {
    ::web::user::mount $router -connection $connection -policy {tenant example} -config [dict create prefix /user origin $origin \
        google_enabled true google_client_id $clientId google_redirect_uri $origin/user/google/callback] \
        -secret_config [dict create aead_keyset $aeadKeyset mac_keyset $macKeyset \
            email_hash_salt $emailSalt google_client_secret $clientSecret]
}
