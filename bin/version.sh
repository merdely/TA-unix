#!/bin/sh
# SPDX-FileCopyrightText: 2024 Splunk, Inc.
# SPDX-License-Identifier: Apache-2.0

# shellcheck disable=SC1091
. "$(dirname "$0")"/common.sh

PRINTF='END {printf "%s %s %s %s %s %s %s %s %s\n", DATE, MACH_HW_NAME, MACH_ARCH_NAME, KERN_REL, OS_NAME, KERN_VER, OS_REL, OS_VER, DISTRO}'


if [ "$KERNEL" = "Linux" ] ; then
	assertHaveCommand date
	assertHaveCommand uname
	[ -f /etc/os-release ] && . /etc/os-release
	machine_arch=$(uname -p)
	os_release=$(uname -r)
	os_version=$(uname -v)
  distro_name=Linux
	[ -n "$NAME" ] && distro_name=$NAME
	[ -n "$VERSION_ID" ] && os_release=$VERSION_ID
	[ -n "$VERSION_ID" ] && os_version=$VERSION_ID
	[ -r /etc/debian_version ] && grep -Eq "^[0-9.]+$" /etc/debian_version && os_release=$(cat /etc/debian_version)
	[ "$BUILD_ID" = "rolling" ] && os_release=rolling
	[ "$BUILD_ID" = "rolling" ] && os_version=rolling
	which dpkg > /dev/null 2>&1 && machine_arch=$(dpkg --print-architecture)
	[ "$NAME" = "Arch Linux" -o "$NAME" = "Arch Linux ARM" ] && machine_arch=$(uname -m | sed -r "s/(armv7l|aarch64)/arm64/;s/x86_64/amd64/")

	CMD="eval date ; echo $distro_name ; eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v ; echo $machine_arch; echo $os_release; echo $os_version"
elif [ "$KERNEL" = "Darwin" ] ; then
	assertHaveCommand date
	assertHaveCommand uname
	assertHaveCommand sw_vers
	os_release=$(sw_vers --productVersion)
	CMD="eval date ; echo MacOS ; eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v ; eval uname -p; echo $os_release; echo $os_release"
elif [ "$KERNEL" = "SunOS" ]  [ "$KERNEL" = "FreeBSD" ] ; then
	assertHaveCommand date
	assertHaveCommand uname
	CMD='eval date ; echo $KERNEL ; eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v ; eval uname -p;'
elif [ "$KERNEL" = "HP-UX" ] ; then
	# HP-UX lacks -p switch.
	assertHaveCommand date
	assertHaveCommand uname
	CMD='eval date ; echo HP-UX ; eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v'
elif [ "$KERNEL" = "AIX" ] ; then
	# AIX uses oslevel for version and release switch.
	assertHaveCommand date
	assertHaveCommand uname
	CMD='eval date ; echo AIX ; eval uname -m ; eval oslevel -r ; eval uname -s ; eval oslevel -s'
fi

# Get the date.
# shellcheck disable=SC2016
PARSE_0='NR==1 {DATE=$0}'
# shellcheck disable=SC2016
PARSE_1='NR==2 {DISTRO="distro_name=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_2='NR==3 {MACH_HW_NAME="machine_hardware_name=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_3='NR==4 {OS_REL="os_release=\"" $0 "\"";KERN_REL="kernel_release=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_4='NR==5 {OS_NAME="os_name=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_5='NR==6 {OS_VER="os_version=\"" $0 "\"";KERN_VER="kernel_version=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_6='NR==7 {MACH_ARCH_NAME="machine_architecture_name=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_7='NR==8 {OS_REL="os_release=\"" $0 "\""}'
# shellcheck disable=SC2016
PARSE_8='NR==9 {OS_VER="os_version=\"" $0 "\""}'

MASSAGE="$PARSE_0 $PARSE_1 $PARSE_2 $PARSE_3 $PARSE_4 $PARSE_5 $PARSE_6 $PARSE_7 $PARSE_8"

$CMD | tee "$TEE_DEST" | $AWK "$MASSAGE $PRINTF"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $PRINTF'" >> "$TEE_DEST"
