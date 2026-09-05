# Task 3: journalctl

## What it's for

`journalctl` reads the logs collected by systemd's logging service (journald). Instead of every service writing its own log file under `/var/log/`, systemd keeps everything in one place (kernel messages, boot logs, every service's stdout/stderr) and `journalctl` is how you query it. Main use case: something's broken, go check what a service actually logged when it failed.

## Commands I tried

```bash
journalctl --no-pager -n 5              # last 5 log lines, any service
systemctl list-units --type=service --state=running   # find a real service name to inspect
journalctl -u systemd-resolved -n 10    # logs for just one specific service
```

(`--no-pager` just makes it print straight to the terminal instead of opening `less`, easier for me to copy output from.)

## What came back

Last 5 entries overall:
```
Sep 05 14:35:10 Sachith-PC userdel[1531]: removed shadow group 'useraddtest' owned by 'useraddtest'
Sep 05 14:35:10 Sachith-PC sudo[1529]: pam_unix(sudo:session): session closed for user root
Sep 05 14:35:25 Sachith-PC systemd-resolved[177]: Clock change detected. Flushing caches.
Sep 05 14:35:26 Sachith-PC systemd-resolved[177]: Clock change detected. Flushing caches.
Sep 05 14:35:36 Sachith-PC systemd[377]: launchpadlib-cache-clean.service - Clean up old files in the Launchpadlib cache was skipped because of an unmet condition check
```
Kind of a nice coincidence — the `userdel`/`sudo` lines at the top are literally the account cleanup from Task 2, so this is real proof the journal is tracking actual system activity as it happens, not something staged.

To find a real service to query with `-u`, I listed what's actually running:
```
$ systemctl list-units --type=service --state=running --no-pager
  UNIT                        LOAD   ACTIVE SUB     DESCRIPTION
  cron.service                loaded active running Regular background program processing daemon
  dbus.service                loaded active running D-Bus System Message Bus
  systemd-journald.service    loaded active running Journal Service
  systemd-resolved.service    loaded active running Network Name Resolution
  ...
```

Picked `systemd-resolved` (the DNS resolver service) since it was clearly active:
```
$ journalctl -u systemd-resolved --no-pager -n 10
Sep 05 14:33:22 Sachith-PC systemd-resolved[177]: Clock change detected. Flushing caches.
Sep 05 14:33:23 Sachith-PC systemd-resolved[177]: Clock change detected. Flushing caches.
... (same message repeated a bunch of times)
```
Every entry is the same "Clock change detected" message — turns out this is just a WSL quirk, WSL's clock drifts slightly and resyncs constantly, and resolved logs every time it notices. Not a real problem, just noisy — but it's a good example of exactly what `-u <service>` is for: instead of scrolling through the entire system journal, I could isolate one service and immediately see its own pattern of behavior.

## Done
- Know what journalctl is for
- Read general system logs
- Scoped logs down to one specific service and understood why it was logging what it was
