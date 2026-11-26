#!/bin/bash

# Source helper scripts directly so secrets/salts/hashes stay in-process
. ./database.sh
. ./encryption.sh

# Initialize database if your database.sh defines init_db 
init_db

Usnm=""
MASTER_KEY=""

while true; do
  CHOICE=$(whiptail --title "Password Manager" --menu "Logged in as: ${Usnm:-None}\n\nHow may I be of help today?" 17 60 6 \
    "1." "User Login / Register" \
    "2." "Lookup Domain Password" \
    "3." "Add new Password" \
    "4." "Edit existing password" \
    "5." "List Domains" \
    "6." "Exit" 3>&1 1>&2 2>&3) || continue

  case "$CHOICE" in
    "1.")
      inputUser=$(whiptail --title "User ID input" --inputbox "Please enter your username" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$inputUser" ]] && continue

      Pswd=$(whiptail --title "Password input" --passwordbox "Please enter your password" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Pswd" ]] && continue

      if user_record=$(getUser "$inputUser" 2>/dev/null) && [[ -n "$user_record" ]]; then
        IFS='|' read -r salt stored_hash <<< "$user_record"
        computed_hash=$(hashMasterKey "$Pswd" "$salt")

        if [[ "$computed_hash" == "$stored_hash" ]]; then
          Usnm="$inputUser"
          MASTER_KEY="$Pswd"
          whiptail --title "Login Successful" --msgbox "Welcome back, $Usnm!" 10 50
        else
          whiptail --title "Access Denied" --msgbox "Invalid password for existing user." 10 50
        fi
      else
        salt=$(generateSalt)
        authHash=$(hashMasterKey "$Pswd" "$salt")
        epoch=$(date +%s)

        if addUser "$inputUser" "$salt" "$authHash" "$epoch"; then
          Usnm="$inputUser"
          MASTER_KEY="$Pswd"
          whiptail --title "User Registered" --msgbox "Account created successfully for $Usnm!" 10 50
        else
          whiptail --title "Registration Error" --msgbox "Failed to register user $inputUser." 10 50
        fi
      fi
      unset Pswd
      ;;

    "2.")
      if [[ -z "$Usnm" || -z "$MASTER_KEY" ]]; then
        whiptail --title "Master Key Required" --msgbox "Please log in or register in Option 1 first." 10 50
        continue
      fi

      Domain=$(whiptail --title "Domain Lookup" --inputbox "Enter the domain name (e.g., github.com):" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Domain" ]] && continue

      if ! PassRecord=$(getPassword "$Usnm" "$Domain" 2>/dev/null) || [[ -z "$PassRecord" ]]; then
        whiptail --title "Not Found" --msgbox "No password found for $Domain under user $Usnm." 10 50
        continue
      fi

      IFS='|' read -r encPass iv epoch <<< "$PassRecord"
      if ! plainPass=$(decrypt "$MASTER_KEY" "$encPass" "$iv" "$epoch" 2>/dev/null); then
        whiptail --title "Decryption Error" --msgbox "Failed to decrypt password for $Domain." 10 50
        continue
      fi

      whiptail --title "Domain Password" --msgbox "User: $Usnm\nDomain: $Domain\nPassword: $plainPass" 12 60
      unset plainPass
      ;;

    "3.")
      if [[ -z "$Usnm" || -z "$MASTER_KEY" ]]; then
        whiptail --title "Master Key Required" --msgbox "Please log in or register in Option 1 first." 10 50
        continue
      fi

      Domain=$(whiptail --title "Domain" --inputbox "Enter the domain name (e.g., github.com):" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Domain" ]] && continue

      DomainPswd=$(whiptail --title "Password" --passwordbox "Enter the password to store:" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$DomainPswd" ]] && continue

      if EncryptedOutput=$(encrypt "$MASTER_KEY" "$DomainPswd" 2>/dev/null); then
        IFS='|' read -r encPass iv epoch <<< "$EncryptedOutput"
        if addPassword "$Usnm" "$Domain" "$encPass" "$iv" "$epoch"; then
          whiptail --title "Saved" --msgbox "Password stored for $Domain." 10 50
        else
          whiptail --title "Save Error" --msgbox "Failed to save password for $Domain." 10 50
        fi
      else
        whiptail --title "Encryption Error" --msgbox "Failed to encrypt password for $Domain." 10 50
      fi
      unset DomainPswd
      ;;

    "4.")
      # Leave for the other contributor
      ;;

    "5.")
      # Leave for the other contributor
      ;;

    "6.")
      break
      ;;

    *)
      continue
      ;;
  esac
done
