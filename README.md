# Password Manager

A simple terminal-based password manager built with Bash, `whiptail`, SQLite, and OpenSSL.

## Features

- **User Login / Registration**: Stores salted SHA-256 master key hashes in SQLite.
- **Encrypted Vault**: Encrypts stored domain passwords using AES-256-CBC (`openssl`) with random IVs.
- **Terminal UI (`TUI.sh`)**:
  1. User Login / Register
  2. Lookup Domain Password
  3. Add New Password
  4. Edit Existing Password *(WIP)*
  5. List Domains *(WIP in TUI; supported in `database.sh`)*
  6. Exit

## Requirements

Make sure these are installed (standard on most Linux setups):

- `bash`
- `whiptail`
- `sqlite3`
- `openssl`

## Usage

Make the scripts executable if needed, then run the TUI:

```bash
chmod +x TUI.sh database.sh encryption.sh
./TUI.sh
```

On first run, `vault.db` is created automatically with `600` permissions.

1. Pick **1** to log in or register a new account.
2. Use **2** to look up and decrypt a password for a domain.
3. Use **3** to encrypt and save a new domain password.

## Project Structure

- `TUI.sh` — `whiptail` menu interface
- `database.sh` — SQLite helpers (`vault.db` schema and CRUD functions; also works as a CLI)
- `encryption.sh` — Salt generation, SHA-256 master key hashing, and AES-256-CBC encrypt/decrypt helpers
