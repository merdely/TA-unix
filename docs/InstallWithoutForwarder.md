# Installation Instructions

## Linux

1. Download the latest release from
    https://git.erdelynet.com/mike/TA-unix/releases/latest
1. Extract to /srv with:
    `tar -C /srv -xphf /path/to/tarball.tgz`
1. Create /etc/nix_ta.conf with:
    ```
    ta_home=/srv/TA-unix
    tag_prefix=nix_ta_
    syslog_server=<your_syslog_server>
    run_minute=2
    run_hour=6
    ```
    See: extra/run_nix_ta_commands for more information
1. Enable/disable scripts by editing /srv/TA-unix/local/inputs.conf
1. Set up a 'splunk' user
1. Set up a crontab for the splunk user with:
    ```
    * * * * * /srv/TA-unix/extra/run_nix_ta_commands
    ```

