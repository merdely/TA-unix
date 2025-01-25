#!/bin/sh
# Copyright (C) 2025 Michael Erdely All Rights Reserved.
# SPDX-FileCopyrightText: 2024 Splunk, Inc.
# SPDX-License-Identifier: Apache-2.0

# jscpd:ignore-start
# shellcheck disable=SC1091
. "$(dirname "$0")"/common.sh

HEADER='Name    rxPackets_PS txPackets_PS rxKB_PS txKB_PS'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%s    %s  %s  %s  %s\n", Name, rxPackets_PS, txPackets_PS, rxKB_PS, txKB_PS}'

# Note: For FreeBSD, bsdsar package needs to be installed. Output matches linux equivalent
if [ "$KERNEL" = "Linux" ] ; then
    CMD='sar -n DEV 1 2'
    # shellcheck disable=SC2016
    FILTER='($0 !~ "Average" || $0 ~ "sar" || $2 ~ "lo|IFACE") {next}'
    # shellcheck disable=SC2016
    FORMAT='{Name=$2; rxPackets_PS=$3; txPackets_PS=$4; rxKB_PS=$5; txKB_PS=$6}'
elif [ "$KERNEL" = "SunOS" ] ; then
    if [ "$SOLARIS_10" = "true" ] ; then
        CMD='netstat -i 1 2'
        FILTER='(NR==2||NR==3){next}'
        # shellcheck disable=SC2016
        EXTRACT_NAME='NR==1 {for (i=0; i< NF/3 -1; i++) { name[i]=$(i*3 + 2); location[name[i]]=i }}'
        # shellcheck disable=SC2016
        EXTRACT_FIELDS=' NR==4 { for (each in name){ printf "%s     %s     %s      %s      %s\n",name[each], $(5*location[name[each]]+1), $(5*location[name[each]]+3), "<n/a>","<n/a>"; }}'
        PRINTF=''
        FORMAT="$EXTRACT_NAME $EXTRACT_FIELDS"

    elif [ "$SOLARIS_11" = "true" ] ; then
		if ! dlstat 1 1 > /dev/null 2>&1 ; then
			CMD='netstat -i 1 2'
			FILTER='(NR==2||NR==3){next}'
            # shellcheck disable=SC2016
			EXTRACT_NAME='NR==1 {for (i=0; i< NF/3 -1; i++) { name[i]=$(i*3 + 2); location[name[i]]=i }}'
            # shellcheck disable=SC2016
			EXTRACT_FIELDS=' NR==4 { for (each in name){ printf "%s     %s     %s      %s      %s\n",name[each], $(5*location[name[each]]+1), $(5*location[name[each]]+3), "<n/a>","<n/a>"; }}'
			PRINTF=''
			FORMAT="$EXTRACT_NAME $EXTRACT_FIELDS"
		else
			CMD='dlstat 1 2'
			FILTER='(NR==1||NR==2){next}'
            # shellcheck disable=SC2016
			FORMAT='
				function to_kbps(KBPS_param){
					if(KBPS_param ~ /[Kk]$/){ sub(/[A-Za-z]/,"",KBPS_param); return(KBPS_param); }
					else if(KBPS_param ~ /[Gg]$/){ sub(/[A-Za-z]/,"",KBPS_param); return(KBPS_param*1024*1024); }
					else if(KBPS_param ~ /[Mm]$/){ sub(/[A-Za-z]/,"",KBPS_param); return(KBPS_param*1024); }
					sub(/[a-zA-Z]/,"",KBPS_param); return(KBPS_param/1024);
				}
				{Name=$1; rxPackets_PS=$2; txPackets_PS=$4; rxKB_PS=to_kbps($3); txKB_PS=to_kbps($5);}'
		fi
    else
        CMD='sar -n DEV 1 2'
        # shellcheck disable=SC2016
        FILTER='($0 ~ "Time|sar| lo") {next}'
        # shellcheck disable=SC2016
        FORMAT='{Name=$2; rxPackets_PS=$5; txPackets_PS=$6; rxKB_PS=$3; txKB_PS=$4}'
    fi
elif [ "$KERNEL" = "AIX" ] ; then
    # Sample output: http://www-01.ibm.com/support/knowledgecenter/ssw_aix_61/com.ibm.aix.performance/nestat_in.htm
    CMD='eval netstat -i -Z; sleep 1; netstat -in'
    # shellcheck disable=SC2016
    FILTER='($0 ~ "Name|sar|lo") {next}'
    # shellcheck disable=SC2016
    FORMAT='{Name=$1; rxPackets_PS=$5; txPackets_PS=$7; rxKB_PS="?"; txKB_PS="?"}'
elif [ "$KERNEL" = "Darwin" ] ; then
    CMD='eval ifconfig -a -u | awk "/^[^ \t]/{i=substr(\$1,1,length(\$1)-1)}/status: active/{print i}" | while read -r int; do netstat -bnI $int -w 1 | head -n3 | sed "s/^/$int/"; done'
    # shellcheck disable=SC2016
    FILTER='$2~/^(input|packets)$/{next}'
    # shellcheck disable=SC2016
    FORMAT='{Name=$1; rxPackets_PS=$2; txPackets_PS=$5; rxKB_PS=$4/1024; txKB_PS=$7/1024}'
elif [ "$KERNEL" = "HP-UX" ] ; then
    # Sample output: http://h20565.www2.hp.com/hpsc/doc/public/display?docId=emr_na-c02263324
    CMD='netstat -i 1 2'
    # shellcheck disable=SC2016
    FILTER='($0 ~ "Name|sar| lo") {next}'
    # shellcheck disable=SC2016
    FORMAT='{Name=$1; rxPackets_PS=$5; txPackets_PS=$7; rxKB_PS=?; txKB_PS=?}'
elif [ "$KERNEL" = "OpenBSD" ] ; then
    CMD='eval ifconfig -a | awk "/UP/ && /RUNNING/ && \$1 != \"lo0:\" {print substr(\$1, 1, length(\$1) - 1)}" | while read -r int; do echo $int $(netstat -bnI $int -w 1 | head -n4 | tail -n1) $(netstat -nI $int -w 1 | head -n 4 | tail -n1 ); done'
    # shellcheck disable=SC2016
    FORMAT='{Name=$1; rxPackets_PS=$6; txPackets_PS=$8; rxKB_PS=$2/1024; txKB_PS=$2/1024}'
elif [ "$KERNEL" = "FreeBSD" ] ; then
    CMD='sar -n DEV 1 2'
    # shellcheck disable=SC2016
    FILTER='($0 !~ "Average" || $0 ~ "sar" || $2 ~ "lo|IFACE") {next}'
    # shellcheck disable=SC2016
    FORMAT='{Name=$2; rxPackets_PS=$3; txPackets_PS=$4; rxKB_PS=$5; txKB_PS=$6}'
fi

assertHaveCommand "$CMD"
$CMD | tee "$TEE_DEST" | $AWK "$HEADERIZE $FILTER $FORMAT $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FILTER $FORMAT $PRINTF' header=\"$HEADER\"" >> "$TEE_DEST"
# jscpd:ignore-end
