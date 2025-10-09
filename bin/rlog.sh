#!/bin/sh
# Copyright (C) 2025 Michael Erdely All Rights Reserved.
# SPDX-FileCopyrightText: 2025 Splunk LLC
# SPDX-License-Identifier: Apache-2.0
#
# credit for improvement to http://splunk-base.splunk.com/answers/41391/rlogsh-using-too-much-cpu

# shellcheck disable=SC1091
. "$(dirname "$0")"/common.sh

if [ -n "$SPLUNK_DB" ]; then
  OLD_SEEK_FILE=$SPLUNK_HOME/var/run/splunk/unix_audit_seekfile # For handling upgrade scenarios
  SEEK_FILE=$SPLUNK_HOME/var/run/splunk/unix_audit_seektime
else
  # handle the case where this is not being run by the Splunk user from Splunk
  OLD_SEEK_FILE=$HOME/.splunk_unix_audit_seekfile # For handling upgrade scenarios
  SEEK_FILE=$HOME/.splunk_unix_audit_seektime
fi
CURRENT_AUDIT_FILE=/var/log/audit/audit.log # For handling upgrade scenarios
AUDIT_LOG_DIR="/var/log/audit"
AUDIT_FILES=$(ls -1 "${AUDIT_LOG_DIR}"/audit.log "${AUDIT_LOG_DIR}"/audit.log.[0-9]* 2>/dev/null | sort -V)

if [ "$KERNEL" = "Linux" ] ; then
    assertHaveCommand service
    assertHaveCommandGivenPath /sbin/ausearch
    TMP_ERROR_FILTER_FILE=$(mktemp /tmp/splunk_rlog.XXXXXXXXXXXXXXXXX) # For filering out "no matches" error from stderr
    if [ -n "$(service auditd status 2>/dev/null)" ] && [ "$(service auditd status 2>/dev/null)" ] ; then
            CURRENT_TIME=$(date --date="1 seconds ago"  "+%x %T") # 1 second ago to avoid data loss

            if [ -e "$SEEK_FILE" ] ; then
                SEEK_TIME=$(head -1 "$SEEK_FILE")
                for AUDIT_FILE in $AUDIT_FILES; do
                    # shellcheck disable=SC2086
                    /sbin/ausearch -i -ts $SEEK_TIME -te $CURRENT_TIME -if "$AUDIT_FILE" 2>"$TMP_ERROR_FILTER_FILE" | grep -v "^----"
                    # shellcheck disable=SC2086
                    grep -v "<no matches>" <"$TMP_ERROR_FILTER_FILE" 1>&2
                done

            elif [ -e "$OLD_SEEK_FILE" ] ; then
                rm -rf "$OLD_SEEK_FILE" # remove previous checkpoint
                for AUDIT_FILE in $AUDIT_FILES; do
                    # start ingesting from the first entry of current audit file
                    # shellcheck disable=SC2086
                    /sbin/ausearch -i -te $CURRENT_TIME -if "$AUDIT_FILE" 2>"$TMP_ERROR_FILTER_FILE" | grep -v "^----"
                    # shellcheck disable=SC2086
                    grep -v "<no matches>" <"$TMP_ERROR_FILTER_FILE" 1>&2
                done

            else
                # no checkpoint found
                for AUDIT_FILE in $AUDIT_FILES; do
                    # shellcheck disable=SC2086
                    /sbin/ausearch -i -te $CURRENT_TIME -if "$AUDIT_FILE" 2>"$TMP_ERROR_FILTER_FILE" | grep -v "^----"
                    # shellcheck disable=SC2086
                    grep -v "<no matches>" <"$TMP_ERROR_FILTER_FILE" 1>&2
                done

            fi
            echo "$CURRENT_TIME" > "$SEEK_FILE" # Checkpoint+

    else   # Added this condition to get error logs
        echo "error occured while running 'service auditd status' command in rlog.sh script. Output : $(service auditd status). Command exited with exit code $?" 1>&2
    fi
    # remove temporary error redirection file if it exists
    # shellcheck disable=SC2086
    rm $TMP_ERROR_FILTER_FILE 2>/dev/null

elif [ "$KERNEL" = "SunOS" ] ; then
    :
elif [ "$KERNEL" = "Darwin" ] ; then
    :
elif [ "$KERNEL" = "HP-UX" ] ; then
	:
elif [ "$KERNEL" = "OpenBSD" ] ; then
	:
elif [ "$KERNEL" = "FreeBSD" ] ; then
	:
fi
