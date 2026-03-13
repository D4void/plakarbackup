# plakarbackup

Bash wrapper script for [plakar](https://plakar.io/) - Streamlined backup tool with email notifications and INI-based configuration management.

## 📋 Description

`plakarbackup` is a Bash script that simplifies the use of the [plakar](https://plakar.io/) backup tool. It provides:
- Backup files/directories to plakar repositories
- Synchronize backups to other repositories
- Email notifications on success or failure
- Backup configuration management via INI files
- Automatic logging of all operations

## 🚀 Installation

### Prerequisites

**Required:**
- `plakar` - [Download plakar](https://plakar.io/download/)
  - Must be installed at `/usr/bin/plakar`

**Optional:**
- `swaks` - For sending emails if no MTA (exim, postfix) is configured
  - Or a configured system MTA (exim, postfix, etc.)

### Script Installation

```bash
# Clone the repository
git clone https://github.com/D4void/plakarbackup.git
cd plakarbackup

# Make the script executable
chmod +x plakarbackup.sh

# Copy the script to a PATH directory (optional)
sudo cp plakarbackup.sh /usr/local/bin/plakarbackup
```

## ⚙️ Configuration

### INI File

The script uses INI configuration files to manage backup settings.

**Search hierarchy:**
1. `~/.plakarbackup-<repo_name>.ini` (priority)
2. `~/.plakarbackup.ini` (fallback)

**Create your configuration file:**

```bash
# Copy the example
cp plakarbackup.ini.example ~/.plakarbackup.ini

# Secure permissions (important as it contains passwords)
chmod 600 ~/.plakarbackup.ini

# Edit the configuration
nano ~/.plakarbackup.ini
```

### INI File Structure

```ini
; Mail settings
MTA=false                    ; true if system MTA configured, false to use swaks
MAILSERVER=smtp.example.com  ; SMTP server
MAILPORT=587                 ; SMTP port (587 for TLS, 465 for SSL)
MAILLOGIN=user@example.com   ; SMTP login
MAILPASS=yourPassword        ; SMTP password
FROM=backup@example.com      ; Sender address
TO=admin@example.com         ; Recipient address

; Files to backup (one line per file/directory)
FILE=/home/user/documents
FILE=/etc/nginx
FILE=/var/www

; Sync target repositories (optional)
STO=remote-backup
STO=secondary-backup

; PLAKAR BACKUP OPTIONS (optional)
; Additional options passed to the 'plakar backup' command. Can also be provided via CLI with -opts "..."
; Don't forget to simple quote file path (e.g -ignore)
;OPTS=

```

### Initialize Plakar Repositories

**Important:** Before using this script, you must initialize your plakar repositories. This is a one-time setup for each repository.

```bash
# First, add plakar storage location
plakar store add mybackup /mnt/mybackup

# Then, create your backup repository
plakar at "@mybackup" create

# For sync targets, create those repositories as well
plakar store add remote-backup /mnt/remote-backup
plakar at "@remote-backup" create

plakar store add secondary-backup /mnt/secondary-backup
plakar at "@secondary-backup" create
```

For more information, refer to the [plakar documentation](https://plakar.io/docs/).

## 📖 Usage

### Syntax

```bash
plakarbackup [-h] [-m] [-mf] [-sto <repo1>,<repo2>, ...] [-opts "<plakar backup options>"] <repo_name> [<files>]
```

### Options

| Option | Description |
|--------|-------------|
| `-h` | Display help |
| `-m` | Send log by email (success AND failure) |
| `-mf` | Send log by email ONLY on failure |
| `-sto <repos>` | Specify sync target repositories (comma-separated) |
| `-opts "<plakar backup options>"` | Specify additional options to pass to plakar backup command  (refer to plakar doc) |
| `<repo_name>` | Plakar repository name (required) |
| `<files>` | Files/directories to backup (optional, overrides INI config) |

### Examples

#### Simple backup with files from INI
```bash
plakarbackup mybackup
```

#### Backup with email notification on failure
```bash
plakarbackup -mf mybackup
```

#### Backup with email notification always
```bash
plakarbackup -m mybackup
```

#### Backup specific files (overrides INI)
```bash
plakarbackup mybackup /home/user/important /etc/config
```

#### Backup with sync to other repositories
```bash
plakarbackup -sto remote-backup,cloud-backup mybackup
```

#### Complete backup with email and sync
```bash
plakarbackup -m -sto remote1,remote2 mybackup /data/important
```

## 📁 Generated Files

### Logs

Logs are automatically created in your home directory:
```
~/.plakarbackup-<repo_name>.log
```

Each log contains:
- Timestamp of each operation
- Details of backups performed
- Sync results
- Any error messages

### Log Format

```
=======================- PLAKARBACKUP LOG -=========================
2026/01/26-14h30m15s: Launching backup.
2026/01/26-14h30m16s: Backing up /home/user/data to mybackup ...
[plakar output]
2026/01/26-14h30m45s: Backup successfull *_*
==================- END of PLAKARBACKUP LOG -=======================
```

## 🔧 Advanced Usage

### Per-Repository Configuration

Create specific configurations per repository:

```bash
# Configuration for "production" repository
~/.plakarbackup-production.ini

# Configuration for "dev" repository
~/.plakarbackup-dev.ini
```

### Automation with Cron

Add a cron job for automatic backups:

```bash
# Edit crontab
crontab -e

# Example: daily backup at 2 AM with email on failure
0 2 * * * /usr/local/bin/plakarbackup -mf production

# Example: backup every 6 hours
0 */6 * * * /usr/local/bin/plakarbackup mybackup
```

### Test Email Configuration

```bash
# Test with a small file
plakarbackup -m testbackup /tmp/test.txt
```

## 🐛 Troubleshooting

### Plakar repository not found
```
Error: plakar repository '@myrepo' not found or not accessible.
```
**Solution:** Verify the repository exists with `plakar at @myrepo ls`

### Email sending error
```
Warning: Failed to send email with swaks.
```
**Solutions:**
- Check your SMTP settings in the INI file
- Test swaks manually
- Switch to `MTA=true` if you have a configured system MTA

### INI file not found
```
Error: ~/.plakarbackup.ini doesn't exist. Can't init settings.
```
**Solution:** Create the INI file from the provided example

### No files to backup
```
Error: No files to backup specified in cli or .ini file...
```
**Solution:** Add `FILE=` lines in your INI or specify files on the command line

## 🔒 Security

- **INI file permissions:** INI files contain passwords. Always use `chmod 600`:
  ```bash
  chmod 600 ~/.plakarbackup*.ini
  ```

- **Log storage:** Logs may contain sensitive information. Review their content regularly.

- **Plakar:** This script relies on plakar's native security features (encryption, deduplication, etc.).

## 📝 License

Copyright (C) 2026 - D4void

This program is free software licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Plakar official website](https://plakar.io/)
- [Plakar documentation](https://plakar.io/docs/)
- [Plakar downloads](https://plakar.io/download/)
- [Project GitHub](https://github.com/D4void/plakarbackup)

## 📜 Changelog

### v0.2 (2026/01/17)
- Added `-sto` option for syncing to other repositories
- Multi-repository sync support

### v0.1 (2026/01/16)
- Initial script creation
- Backup management with plakar
- Email notifications
- INI file configuration

---

*This README was initially generated with AI assistance.*

