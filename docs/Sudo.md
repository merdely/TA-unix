# Sudo Usage

Some commands may need to use sudo or doas to execute. Below is documentation
for those cases.

## MacOS/Darwin service.sh

The service.sh script searches users' home directories and a splunk user does
not have rights to do that.

Create a file like /etc/sudoers.d/splunk and add:

```
splunk ALL=(root) NOPASSWD: /usr/bin/find /Users -name loginwindow.plist
```

## Docker

Either add the splunk user to the docker group or run the command with sudo.
To make sudo work, create a file like /etc/sudoers.d/splunk and add:

```
splunk ALL=(root) NOPASSWD: /usr/bin/docker stats --no-stream --no-trunc --all
splunk ALL=(root) NOPASSWD: /usr/bin/docker ps --all --no-trunc --format *
splunk ALL=(root) NOPASSWD: /usr/bin/docker inspect -f *
```

## Debian/Ubuntu apt update

A splunk user does not have the ability to update the package cache.
To make sudo work, create a file like /etc/sudoers.d/splunk and add:

```
splunk ALL=(root) NOPASSWD: /usr/bin/apt update
```

## Arch Linux pacman update cache

A splunk user does not have the ability to update the package cache.
To make sudo work, create a file like /etc/sudoers.d/splunk and add:

```
splunk ALL=(root) NOPASSWD: /usr/bin/pacman -Syy
```

