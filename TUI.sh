#!/bin/bash

# . ./database.sh "" ""
./database.sh init
. ./encryption.sh "" ""
MASTER_KEY=2143
# infinite while loop till the user enters input number 5
while true; do
  CHOICE=$(whiptail --title "Password Manager" --menu "How may I be of help today?" 15 60 5 \
    "1." "User Login (UID + Password)" \
    "2." "Get details of existing user" \
    "3." "Add new Password" \
    "4." "Edit existing password" \
    "5." "List Domains" \
    "6." "Exit" 3>&1 1>&2 2>&3)

  case $CHOICE in
    "1.")
      Usnm=$(whiptail --title "User ID input" --inputbox "Please enter your username" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Usnm" ]] && continue

      Pswd=$(whiptail --title "Password input" --passwordbox "Please enter your password" 15 60 3>&1 1>&2 2>&3) || continue
      [[ -z "$Pswd" ]] && continue

      # Check if user already exists in the database
      if user_record=$(bash ./database.sh get-user "$Usnm" 2>/dev/null); then
          # User exists: verify master password
          IFS='|' read -r salt stored_hash <<< "$user_record"
          computed_hash=$(hashMasterKey "$Pswd" "$salt")
          
          if [[ "$computed_hash" == "$stored_hash" ]]; then
              whiptail --title "Login Successful" --msgbox "Welcome back, $Usnm!" 10 50
          else
              whiptail --title "Access Denied" --msgbox "Invalid password for existing user." 10 50
          fi
      else
          # User does not exist: register new user
          salt=$(generateSalt)
          authHash=$(hashMasterKey "$Pswd" "$salt")
          epoch=$(date +%s)

          bash ./database.sh add-user "$Usnm" "$salt" "$authHash" "$epoch"
          whiptail --title "User Registered" --msgbox "Account created successfully for $Usnm!" 10 50
      fi
      ;;
    "2.")
      Usnm=$(whiptail --title "User ID" --inputbox "Enter the user ID of the person you want to add password for" 15 60 3>&1 1>&2 2>&3)
      UserRecord=$(bash ./database.sh get-user "$Usnm")
      IFS='|' read -r salt authHash <<< "$UserRecord"
      whiptail --title "User Details" --msgbox "User ID:$Usnm\nSalt:$salt\nAuthHash:$authHash" 15 60
      ;;
    "3".)
      
      	# 1. Prompt the user for the necessary details
      Usnm=$(whiptail --title "User ID" --inputbox "Enter the username:" 15 60 3>&1 1>&2 2>&3)
      Domain=$(whiptail --title "Domain" --inputbox "Enter the domain name (e.g., github.com):" 15 60 3>&1 1>&2 2>&3)
      Pswd=$(whiptail --title "Password" --passwordbox "Enter the password to store:" 15 60 3>&1 1>&2 2>&3)
      
      EncryptedOutput=$(encrypt "$MASTER_KEY" "$Pswd")
      IFS='|' read -r encPass iv epoch <<< "$EncryptedOutput"
      bash ./database.sh add-pass "$Usnm" "$Domain" "$encPass" "$iv" "$epoch"
      ;;
    "4.")
      ;; #open the database.sh file and learn what parameters you need to add
     "5.")
      ;; #same
    "6.")
      clear
      exit 0
      ;;
  esac
done
