#!/bin/bash

# Source helper scripts directly so secrets/salts/hashes stay in-process
. ./database.sh
. ./encryption.sh

# Initialize database if your database.sh defines init_db (adjust name to match yours)
init_db

Usnm=""
MASTER_KEY=""

while true; do
  CHOICE=$(whiptail --title "Password Manager" --menu "How may I be of help today?" 15 60 5 \
    "1." "User Login / Register" \
    "2." "Lookup Domain Password" \
    "3." "Add new Password" \
    "4." "Edit existing password" \
    "5." "List Domains" 3>&1 1>&2 2>&3)

  case "$CHOICE" in
    "1.")
      Usnm=$(whiptail --title "User ID input" --inputbox "Please enter your username" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Usnm" ]] && continue

      Pswd=$(whiptail --title "Password input" --passwordbox "Please enter your password" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Pswd" ]] && continue

      if user_record=$(getUser "$Usnm" 2>/dev/null) && [[ -n "$user_record" ]]; then
        IFS='|' read -r salt stored_hash <<< "$user_record"
        computed_hash=$(hashMasterKey "$Pswd" "$salt")

        if [[ "$computed_hash" == "$stored_hash" ]]; then
          MASTER_KEY="$Pswd"
          whiptail --title "Login Successful" --msgbox "Welcome back, $Usnm!" 10 50
        else
          whiptail --title "Access Denied" --msgbox "Invalid password for existing user." 10 50
        fi
      else
        salt=$(generateSalt)
        authHash=$(hashMasterKey "$Pswd" "$salt")
        epoch=$(date +%s)

        addUser "$Usnm" "$salt" "$authHash" "$epoch"
        MASTER_KEY="$Pswd"
        whiptail --title "User Registered" --msgbox "Account created successfully for $Usnm!" 10 50
      fi
      ;;

    "2.")
      if [[ -z "$MASTER_KEY" ]]; then
        whiptail --title "Master Key Required" --msgbox "Please log in or register in Option 1 first." 10 50
        continue
      fi

      Usnm=$(whiptail --title "User ID" --inputbox "Enter the username:" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Usnm" ]] && continue

      Domain=$(whiptail --title "Domain Lookup" --inputbox "Enter the domain name (e.g., github.com):" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Domain" ]] && continue

      PassRecord=$(getPassword "$Usnm" "$Domain" 2>/dev/null)
      if [[ -z "$PassRecord" ]]; then
        whiptail --title "Not Found" --msgbox "No password found for $Domain under user $Usnm." 10 50
        continue
      fi

      IFS='|' read -r encPass iv _ <<< "$PassRecord"
      plainPass=$(decrypt "$MASTER_KEY" "$encPass" "$iv")

      whiptail --title "Domain Password" --msgbox "User: $Usnm\nDomain: $Domain\nPassword: $plainPass" 12 60
      ;;

    "3.")
      if [[ -z "$MASTER_KEY" ]]; then
        whiptail --title "Master Key Required" --msgbox "Please log in or register in Option 1 first." 10 50
        continue
      fi

      Usnm=$(whiptail --title "User ID" --inputbox "Enter the username:" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Usnm" ]] && continue

      Domain=$(whiptail --title "Domain" --inputbox "Enter the domain name (e.g., github.com):" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Domain" ]] && continue

      DomainPswd=$(whiptail --title "Password" --passwordbox "Enter the password to store:" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$DomainPswd" ]] && continue

      EncryptedOutput=$(encrypt "$MASTER_KEY" "$DomainPswd")
      IFS='|' read -r encPass iv epoch <<< "$EncryptedOutput"
      addPassword "$Usnm" "$Domain" "$encPass" "$iv" "$epoch"
      whiptail --title "Saved" --msgbox "Password stored for $Domain." 10 50
      ;;

    "4.")
      # Leave for the other contributor
      ;;

    "5.")
      # Leave for the other contributor
      ;;

    *)
      continue
      ;;
  esac
done
