# Technical Add-on for Unix and Linux

## Version 9.2.0.3

Fix bug in 9.2.0.2

* Add code I forgot for machine_arch for Linux
* Add Makefile to make making releases easier

## Version 9.2.0.2

Improvements for version.sh

Changes:

* Include kernel_release, kernel_version, and distro_name
* For Linux and MacOS, use actual OS versions/releases instead of
  kernel version/release

## Version 9.2.0.1

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
