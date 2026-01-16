#!/bin/bash
########################################################################################################################
# Script plakarbackup.sh
# Backup data files with plakar
#
#    Copyright (C) 2026 - D4void - d4void@m4he.fr
#    https://github.com/D4void/plakarbackup
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################################################################
# Dependencies:
#  - Require:  plakar
#  - Optional: Swaks (for email) if MTA like exim is not available on the system
########################################################################################################################
# Changelog:
# 2026/01/16 - v0.1 - Creation of plakarbackup.sh
#
########################################################################################################################


ver="0.1"

BANNERINIT="=======================- PLAKARBACKUP LOG -========================="
BANNEREND="==================- END of PLAKARBACKUP LOG -======================="

DEFAULTINI=".plakarbackup.ini"


PLAKAR=/usr/bin/plakar
SWAKS=/usr/bin/swaks

############################################################
# FUNCTIONS
############################################################


__help()
{
	echo
	cat <<END_HELP
plakarbackup -- Backup files with plakar

USAGE: plakarbackup [-h] [-m] [-mf] <repo name> [<files>]

OPTIONS:
	-h this help
	-m send backup log by email - check mail section in .ini file
    -mf send backup log by email only on failure
	
INI FILE:
	.ini file is used to configure backups (directories, mail settings etc).
	For recurring backup, you can define a "~/.<backup name>.ini" file.
	If "~/.plakarbackup-<repo name>.ini" doesn't exist, "~/.plakarbackup.ini" will be used.
	Files put in cli argument have the priority over files possibly defined in the .ini file.


version $ver

plakarbackup.sh  Copyright (C) 2026 - D4void
    This program comes with ABSOLUTELY NO WARRANTY, check LICENSE file for details.
    This is free software, and you are welcome to redistribute it
    under certain conditions, check LICENSE file for details.

END_HELP

exit 0
}

__read_ini () {
	# function to read ini files: search a pattern put in arg and print it
	echo $(awk -v patt="$1" -F "=" '{if (! ($0 ~ /^;/) && $0 ~ patt ) print $2}' $INIFILE)
}

__init_settings() {
	# function to initialise required variables. Values are parsed in the .ini files
	INIFILE="$HOME/.plakarbackup-$REPONAME.ini"
	if [[ ! -f "$INIFILE" ]]; then
		echo "$INIFILE doesn't exist. Using $HOME/$DEFAULTINI"
		INIFILE="$HOME/$DEFAULTINI"
		if [[ ! -f "$INIFILE" ]]; then
			echo "Error: $INIFILE doesn't exist. Can't init settings."; exit 1
		fi
	fi

	
	# Mail settings
	MTA=$(__read_ini "MTA")
	if [[ -z "$MTA" ]]; then
		MTA=false
	fi
	MAILSERVER=$(__read_ini "MAILSERVER")
	MAILPORT=$(__read_ini "MAILPORT")
	MAILLOGIN=$(__read_ini "MAILLOGIN")
	MAILPASS=$(__read_ini "MAILPASS")
	FROM=$(__read_ini "FROM")
	TO=$(__read_ini "TO")


	#FILES TO BACKUP - Create an array
	# if no files are put in cli arguments, reading files to backup in the .ini file
	if [[ ${#FILETAB[@]} -eq 0 ]]; then
		IFS=':' read -ra FILETAB <<< $(awk -v patt="FILE" -F "=" 'BEGIN {ORS=":"} {if (! ($0 ~ /^;/) && $0 ~ patt ) print $2}' $INIFILE)
		if [[ ${#FILETAB[@]} -eq 0 ]]; then
			echo "Error: No files to backup specified in cli or .ini file..."; exit 1
		fi
	fi
}

__error() {
	__log "$1"
	__log "Backup failed!  :'("
	__terminate
	set +o pipefail
	exit "$2"
}

__log() {
	echo $(date '+%Y/%m/%d-%Hh%Mm%Ss:') "$1" | tee -a $LOGFILE
}

__send_mail() {
	if $SUCCESS; then
		SUBJECT="Backup Log: Success ($REPONAME)"
	else
		SUBJECT="Backup Log: Fail! ($REPONAME)"
	fi
	if [[ "$MTA" == "true" ]]; then
		cat "$LOGFILE" | mail -s "$SUBJECT" $TO
	else
		$SWAKS -S --tls -s $MAILSERVER -p $MAILPORT -au $MAILLOGIN -ap $MAILPASS -t $TO -f $FROM --header "Subject: $SUBJECT" --body @$LOGFILE
		if [[ $? -ne 0 ]]; then
			__log "Warning: Failed to send email with swaks."
		fi
	fi
}

__terminate() {
	if $SUCCESS && ! $ALWAYSMAIL ; then
		MAIL=false
	fi
	if $MAIL; then
		if [[ "$MTA" == "true" ]]; then
			__log "Sending an email with MTA."
		else
			__log "Sending an email with swaks."
		fi
		echo -e "\n$BANNEREND\n" | tee -a $LOGFILE
		__send_mail
	else
		echo -e "\n$BANNEREND\n" | tee -a $LOGFILE
	fi
}

__plakar_launch() {
    # Launch plakar backup
    for FILE in "${FILETAB[@]}"; do
        __log "Backing up $FILE ..."
        $PLAKAR at "@$REPONAME" backup "$FILE" 2>&1 | tee -a $LOGFILE
        if [[ $? -ne 0 ]]; then
            __error "Error during plakar backup of $FILE." 1
        fi
    done
}

############################################################
# MAIN
############################################################


# Init variables
MAIL=false
SUCCESS=false
ALWAYSMAIL=false

while [ -n "$1" ]; do
case $1 in
    -h) __help;shift;;
    -m) MAIL=true;ALWAYSMAIL=true;shift;;
    -mf) MAIL=true;shift;;
    --) break;;
    -*) echo "Error: No such option $1. -h for help"; exit 1;;
    *) REPONAME="$1";shift;FILETAB=( "$@" );break;;
esac
done

if [[ -z "$REPONAME" ]]; then
	echo "Error: no repo name specified. See -h for help."; exit 1
fi

# Check plakar availability
if [[ ! -x "$PLAKAR" ]]; then
	echo "Error: plakar not found at $PLAKAR. Please install plakar."; exit 1
fi

# Init settings
__init_settings

# Validate email settings if email is enabled
if $MAIL && [[ "$MTA" != "true" ]]; then
	if [[ -z "$MAILSERVER" || -z "$TO" || -z "$FROM" ]]; then
		echo "Error: Email settings incomplete in INI file (MAILSERVER, TO, FROM required)."; exit 1
	fi
fi

LOGFILE="$HOME/.plakarbackup-$REPONAME.log"

set -o pipefail 1
echo -e "\n$BANNERINIT\n" | tee $LOGFILE
__log "Launching backup."

# Check if plakar repository exists
$PLAKAR at "@$REPONAME" ls >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	__error "Error: plakar repository '@$REPONAME' not found or not accessible." 1
fi

# Make local backup
__plakar_launch

__log "Backup successfull *_*"
SUCCESS=true
__terminate

set +o pipefail
exit 0
