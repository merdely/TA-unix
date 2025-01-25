# Technical Add-on for Unix and Linux

## Version 9.2.0.12 (2025-01-25)

Add Version to update.sh for Darwin

Changes:

* Add version to update.sh for Darwin

## Version 9.2.0.11 (2025-01-25)

Fix Darwin Scripts and Document Sudo

Changes:

* Use sudo in service.sh for Darwin to find user services if not running as root
* Fix parsing the output of softwareupdate command on Darwin in update.sh
* Better document usage of sudo in docs/Sudo.md

## Version 9.2.0.10 (2025-01-25)

Fix OpenBSD Support and Other Bugs

Changes:

* Fix OpenBSD cpu.sh output to match others
* Fix OpenBSD df.sh output (no need for %% here)
* Do not use sudo or doas when running as root
* Use #!/usr/bin/env bash to support OpenBSD in run_nix_ta_commands
* Fix rsyslog example to trim whitespace in run_nix_ta_commands
* Add /usr/local/sbin:/usr/local/bin to PATH in run_nix_ta_commands
* Fix getting hour and minute for OpenBSD in run_nix_ta_commands
  "08" shows up to printf as octal
* Support difference in OpenBSD logger command:
  Requires modifying /etc/syslog.conf and setting facility in /etc/nix_ta.conf

## Version 9.2.0.9 (2025-01-25)

Support OpenBSD

Changes:

* Add OpenBSD support to the scripts
* Fix sysctl usage for FreeBSD in a couple places

## Version 9.2.0.8 (2025-01-23)

Fix df.sh and df_metric.sh

Changes:

* Fix Linux when df outputs a "-"
* Exclude efivars partitions for Linux
* Fix the output on Darwin to match Linux output

## Version 9.2.0.7 (2025-01-20)

Fix run_nix_ta_commands script

Changes:

* Make run_nix_ta_commands (in extra) use /etc/nix_ta.conf for its settings
  instead of hard-coding them in the script

## Version 9.2.0.6 (2025-01-17)

Fix docker script and props

Changes:

* Fix output for docker script (handle lines that didn't have values)
* Fix props.conf LINE_BREAKER for docker

## Version 9.2.0.5 (2025-01-11)

Add script for docker events/metrics and support running TA outside of Splunk

Changes:

* Add docker.sh and docker_metric.sh for collecting docker events/metrics
* Add helper script to extra/ to run the TA commands on systems without
  a Splunk forwarder. The commands can be sent to a syslog server.
  This script is useful for systems with small or read-only filesystems that
  cannot support a Universal Forwarder.
* Add syslog_inputs_nix_ta app to extra/ for ingesting the data from syslog

## Version 9.2.0.4 (2025-01-11)

Make distro_name work everywhere

Changes:

* For MacOS, print MacOS for distro_name
* For others, print $KERNEL for distro_name

## Version 9.2.0.3 (2025-01-11)

Fix bug in 9.2.0.2

Changes:

* Add code I forgot for machine_arch for Linux
* Add Makefile to make making releases easier

## Version 9.2.0.2 (2025-01-11)

Improvements for version.sh

Changes:

* Include kernel_release, kernel_version, and distro_name
* For Linux and MacOS, use actual OS versions/releases instead of
  kernel version/release

## Version 9.2.0.1 (2025-01-09)

Initial fork of the Splunk Add-on for Unix and Linux

Changes:

* Use ip command to determine IP address
  ('hostname -I' does not work on all Linux systems)
* Filter out multiple listing of the same btrfs volume
* Use mktemp for temp files (for times when the TA may be run outside of Splunk)
* If running rlog.sh outside of Splunk, use $HOME to store seek file
* Debian also uses apt
* Arch Linux uses pacman
* Add use of sudo -n for 'apt update' and 'pacman -Syy'
* vmstat uses "K paged out"
* Replace the use of 'sar' with netstat and vm_stat for MacOS
