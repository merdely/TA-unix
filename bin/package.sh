#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 Splunk LLC
# SPDX-License-Identifier: Apache-2.0

# shellcheck disable=SC1091
. "$(dirname "$0")"/common.sh

assertHaveCommand column

HEADER='NAME                                                     VERSION               RELEASE               ARCH        VENDOR                          GROUP'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%-55.55s  %-20.20s  %-20.20s  %-10.10s  %-30.30s  %-20s\n", name, version, release, arch, vendor, group}'

CMD='echo There is no flavor-independent command...'
if [ "$KERNEL" = "Linux" ] ; then
	OSName=$(cat /etc/*release | grep '\bNAME=' | cut -d '=' -f2 | tr ' ' '_' | cut -d\" -f2)
	if $DEBIAN; then
		CMD1="eval dpkg-query -W -f='"
		# shellcheck disable=SC2016
		CMD2='${Package}  ${Version}  ${Architecture}  ${Homepage}\n'
		CMD3="'"
		CMD=$CMD1$CMD2$CMD3
		# shellcheck disable=SC2016
		FORMAT='{name=$1;version=$2;sub("\\.?[^0-9\\.:\\-].*$", "", version); release=$2; sub("^[0-9\\.:\\-]*","",release); if(release=="") {release="?"}; arch=$3; if (NF>3) {sub("^.*:\\/\\/", "", $4); sub("^www\\.", "", $4); sub("\\/.*$", "", $4); vendor=$4} else {vendor="?"} group="?"}'
	elif [ "$OSName" = "Arch_Linux" ] || [ "$OSName" = "Arch_Linux_ARM" ]; then
		CMD="eval pacman -Q"
		# shellcheck disable=SC2016
    FORMAT="{name=\$1;version=\$2; release=\"?\"; arch=\"$(eval uname -m | sed -r "s/(armv7l|aarch64)/arm64/;s/x86_64/amd64/")\"; vendor=\"?\"; group=\"?\"}"
	else
		CMD='eval rpm --query --all --queryformat "%-56{name}  %-21{version}  %-21{release}  %-11{arch}  %-31{vendor}  %-{group}\n"'
		# shellcheck disable=SC2016
		PRINTF='{print $0}'
	fi
elif [ "$KERNEL" = "SunOS" ] ; then
	CMD='pkginfo -l'
	# shellcheck disable=SC2016
	FORMAT='/PKGINST:/ {name=$2 ":"} /NAME:/ {for (i=2;i<=NF;i++) name = name " " $i} /CATEGORY:/ {group=$2} /ARCH:/ {arch=$2} /VERSION:/ {split($2,a,",REV="); version=a[1]; release=a[2]} /VENDOR:/ {vendor=$2; for(i=3;i<=NF;i++) vendor = vendor " " $i}'
	SEPARATE_RECORDS='!/^$/ {next} {release = release ? release : "?"}'
elif [ "$KERNEL" = "AIX" ] ; then
	CMD='eval lslpp -icq | sed "s,:, ," | sed "s,:.*,,"'
	# shellcheck disable=SC2016
	FORMAT='{name=$2 ; version=$3 ; vendor=release=arch=group="?"}'
elif [ "$KERNEL" = "Darwin" ] ; then
	CMD='system_profiler SPApplicationsDataType'
	FILTER='{ if (NR<3) next}'
	# shellcheck disable=SC2016
	FORMAT='{gsub("[^\40-\176]", "", $0)} /:$/ {sub("^[ ]*", "", $0); sub(":$", "", $0); name=$0} /Last Modified: / {vendor=""} /Version: / {version=$2} /Kind: / {arch=$2} /Get Info String: / {sub("^.*: ", "", $0); sub("[Aa]ll [Rr]ights.*$", "", $0); sub("^.*[Cc]opyright", "", $0); sub("^[^a-zA-Z_]*[0-9][0-9[0-9][0-9]", "", $0); sub("^[ ]*", "", $0); vendor=$0}'
	SEPARATE_RECORDS='!/Location:/ {next} {release = "?"; vendor = vendor ? vendor : "?"; group = "?"}'
elif [ "$KERNEL" = "HP-UX" ] ; then
    assertHaveCommand swlist
    CMD='swlist -a revision -a architecture -a vendor_tag'
	# shellcheck disable=SC2016
    FILTER='/^#/ {next} $1=="" {next}'
	# shellcheck disable=SC2016
    FORMAT='{release="?"; group="?"; vendor="?"; name=$1; version=$2; arch=$3} NF==4 {vendor=$4}'
elif [ "$KERNEL" = "OpenBSD" ] ; then
	CMD=pkg_info
	HEADER='NAME                                               VERSION                                            ARCH        '
	HEADERIZE="BEGIN {print \"$HEADER\"; arch=\"$(arch -s)\"}"
	#PRINTF='{ printf "%-50s %-50s %s\n",$1,$2,$3}'
	PRINTF='{name=gensub(/-[0-9].*$/,"",1,$1); suffix=gensub(/^.*-([0-9][^-]*)/,"",1,$1); if (suffix!="") suffix="," suffix; version=gensub(/^.*-([0-9][^-]*)-?.*$/,"\\1",1,$1); printf "%-50s %-50s %s\n", name suffix, version, arch}'
elif [ "$KERNEL" = "FreeBSD" ] ; then
	# the below syntax is valid when using zsh, bash, ksh
	if [[ $KERNEL_RELEASE =~ 10.* ]] || [[ $KERNEL_RELEASE =~ 11.* ]] || [[ $KERNEL_RELEASE =~ 12.* ]] || [[ $KERNEL_RELEASE =~ 13.* ]]; then
		CMD='eval pkg info --raw --all | grep "^name:\|^version:\|^arch:" | cut -d\" -f2'
		HEADER='NAME                                               VERSION                                            ARCH        '
		HEADERIZE="BEGIN {print \"$HEADER\"}"
		# shellcheck disable=SC2016
		PRINTF='{ printf "%-50.50s" (NR%3==0 ? RS:FS),$1}'
	else
		CMD='pkg_info -da'
		# shellcheck disable=SC2016
		FORMAT='/^Information for / {vendor=""; sub(":$", "", $3); name=$3} /^WWW: / {sub("^.*//", "", $2); sub("/.*$", "", $2); sub("^www\134.", "", $2); vendor=$2} /^$/ {blanks+=1} !/^$/ {blanks=0}'
		SEPARATE_RECORDS='(blanks<3) {next} {vendor = vendor ? vendor : "?"; version=release=arch=group="?"}'
	fi
fi

assertHaveCommand "$CMD"
$CMD | tee "$TEE_DEST" | $AWK "$HEADERIZE $FILTER $FORMAT $SEPARATE_RECORDS $PRINTF"  header="$HEADER" | column -t
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FILTER $FORMAT $SEPARATE_RECORDS $PRINTF' header=\"$HEADER\"" >> "$TEE_DEST"
