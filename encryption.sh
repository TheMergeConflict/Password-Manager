#!/bin/bash

encrypt(){
    local MASTER_KEY="$1"
    local password="$2"
    local TIMESTAMP=$(date +%s)

    KEY="$(echo -n "$(echo "$MASTER_KEY" | base64)$TIMESTAMP" | sha256sum | awk '{print $1}')"
    
    local IV="$(openssl rand -hex 16)"

    ENCRYPTED_PASSWORD="$(echo "$password" | openssl enc -aes-256-cbc -a -A -K "$KEY" -iv $IV)"

    echo "$ENCRYPTED_PASSWORD $IV $TIMESTAMP"
}

decrypt(){
    local MASTER_KEY="$1"
    local ENCRYPTED_PASSWORD="$2"
    local date="$3"
    local IV="$4"

    KEY="$(echo -n "$(echo "$MASTER_KEY" | base64)$date" | sha256sum | awk '{print $1}')"

    password="$(echo "$ENCRYPTED_PASSWORD" | openssl enc -d -aes-256-cbc -a -A -K "$KEY" -iv $IV)"

    echo "$password"
}
