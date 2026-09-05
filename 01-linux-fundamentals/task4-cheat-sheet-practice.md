# Task 4: Linux Command Cheat Sheet Practice

Used the cheat sheet from the devops-heros repo (session2-linux/basic-linux.pdf). It's organized into 10 groups of commands. I went through each group and actually ran the ones that made sense to run on my own machine (WSL Ubuntu 24.04). Skipped a few that need sudo/root or are interactive-only (noted at the bottom, with why).

## 1. File & Directory Commands

`ls`, `cd`, `pwd`, `mkdir`, `rm`, `touch`, `cp`, `mv`

```
$ pwd
/home/sachith/devops-homework/linux/cheatsheet-practice

$ mkdir testdir
$ touch testdir/file1.txt
$ cp testdir/file1.txt testdir/file1-copy.txt
$ mv testdir/file1-copy.txt testdir/file2.txt
$ ls -l testdir
total 0
-rw-r--r-- 1 sachith sachith 0 Sep  5 14:44 file1.txt
-rw-r--r-- 1 sachith sachith 0 Sep  5 14:44 file2.txt
```

Nothing surprising here, this is stuff I already use daily. `cp` makes a copy, `mv` renames/moves — same command does both depending on whether the destination is a new name or a different folder.

## 2. File Viewing & Search

`cat`, `less`/`more`, `tail`, `head`, `grep`

```
$ cat /etc/os-release | head -3
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"

$ head -n 3 /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin

$ tail -n 3 /etc/passwd
landscape:x:104:105::/var/lib/landscape:/usr/sbin/nologin
polkitd:x:990:990:User for polkitd:/:/usr/sbin/nologin
sachith:x:1000:1000:,,,:/home/sachith:/bin/bash

$ grep sachith /etc/passwd
sachith:x:1000:1000:,,,:/home/sachith:/bin/bash
```

`head`/`tail` are basically "show me the start/end of a file without opening the whole thing" — useful for huge log files. `grep` searches inside a file for a pattern, here just my own username in `/etc/passwd`. Didn't demo `less`/`more` since they open an interactive pager and don't really produce output I can paste here — but I opened `less /etc/passwd` manually and it works like a scrollable viewer, `q` to quit.

## 3. Process & Service Management

`ps`, `top`/`htop`

```
$ ps -eo user,pid,%cpu,%mem,comm | head -6
USER         PID %CPU %MEM COMMAND
root           1  0.0  0.1 systemd
root           2  0.0  0.0 init-systemd(Ub
root           7  0.0  0.0 init
root          43  0.0  0.2 systemd-journal
root          89  0.0  0.0 systemd-udevd
```

Used `-eo user,pid,%cpu,%mem,comm` instead of the cheat sheet's plain `ps aux` — earlier in the shell scripting task I found `ps aux` prints full command-line arguments, and on my machine that included a live VS Code remote session token. Didn't want that showing up here either, so this trimmed version (process name only, no args) is what I'd actually use when the output might end up somewhere shared.

`top` is interactive (updates live, you quit with `q`), so no static output to show — but I ran it and watched CPU/memory update in real time.

## 4. Disk & Storage

`df`, `du`

```
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G   18G  938G   2% /

$ du -sh testdir
4.0K	testdir
```

`df -h` = how full is the disk. `du -sh <folder>` = how big is this specific folder, `-s` for a single summarized total instead of listing every file.

## 5. Permissions & Ownership

`chmod`, `chown`

```
$ chmod 755 testdir/file1.txt
$ ls -l testdir/file1.txt
-rwxr-xr-x 1 sachith sachith 0 Sep  5 14:44 file1.txt
```

`755` = owner gets read/write/execute, group and others get read/execute only. Didn't run `chown` for real — changing the *owner* of a file needs root, and I didn't want to go create another throwaway sudo session just for this. Conceptually it's `chown newuser:newgroup file`.

## 6. Package Management

`apt install` (Ubuntu), `yum install` (RHEL/CentOS) — skipped running these since they need `sudo` and actually install stuff on my machine, not something to do just to check a box. Understand the idea: `apt`/`yum` are just different package managers depending on the distro family (Debian-based vs RedHat-based).

## 7. Networking Commands

`ping`, `ip a`/`ifconfig`, `netstat`, `curl`, `wget`

```
$ ping -c 3 google.com
PING google.com (142.250.207.174) 56(84) bytes of data.
64 bytes from 142.250.207.174: icmp_seq=1 ttl=116 time=77.8 ms
64 bytes from 142.250.207.174: icmp_seq=2 ttl=116 time=22.3 ms
64 bytes from 142.250.207.174: icmp_seq=3 ttl=116 time=22.3 ms
--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss

$ ip a | grep -A1 eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:aa:c2:73 brd ff:ff:ff:ff:ff:ff

$ curl -sI https://api.github.com | head -3
HTTP/2 200
date: Sat, 05 Sep 2026 14:44:10 GMT
cache-control: public, max-age=60, s-maxage=60
```

`ping` = "is this host reachable / how's the latency." `ip a` = list network interfaces and their IPs (my WSL adapter shows a `192.168.x.x` internal address). `curl -I` fetches just the HTTP headers without downloading the body, good for quickly checking if a site/API is up. Going into way more depth on this whole category in the Networking Fundamentals section anyway.

## 8. Scheduling & Background Jobs

`crontab -e`, `nohup`

Skipped actually editing crontab since `crontab -e` opens an interactive editor (nano/vim) and there's nothing meaningful to screenshot from an empty crontab. The idea is straightforward though: `crontab -e` opens your personal list of scheduled jobs, each line is `minute hour day month weekday command`, so `0 2 * * * /home/user/backup.sh` = run that script every day at 2 AM. `nohup command &` runs something in the background and keeps it running even after you close the terminal / log out.

## 9. User Management

Covered properly in Task 2 (`adduser` vs `useradd`), plus `id`/`groups` below.

```
$ id
uid=1000(sachith) gid=1000(sachith) groups=1000(sachith),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),1001(docker)

$ groups
sachith adm cdrom sudo dip plugdev users docker
```

`id` shows my UID/GID and every group I'm in. `sudo` group in there is why I can run sudo commands, `docker` group is why I can run docker without prefixing every command with sudo (once Docker's set up).

## 10. System Information & Utilities

`uname -a`, `hostname`, `uptime`, `whoami`, `history`, `date`, `clear`

```
$ uname -a
Linux Sachith-PC 6.6.87.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 5 18:30:46 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux

$ hostname
Sachith-PC

$ uptime
14:44:31 up 17:44, 2 users, load average: 1.03, 0.86, 0.72

$ whoami
sachith

$ date
Sat Sep 5 14:44:31 UTC 2026
```

`uname -a` dumps kernel version + architecture in one line — you can see `microsoft-standard-WSL2` in there, confirming this really is WSL and not a native Linux box. `uptime` also shows load average (how busy the CPU has been over the last 1/5/15 min). Didn't paste `history` output since it's just my last few shell commands and not really "evidence" of anything, and `clear` obviously doesn't produce output — it wipes the screen.

## Useful shortcuts (from the cheat sheet, not run — these only make sense live in a terminal)

- `!!` — re-run the last command
- `!n` — re-run command number `n` from `history`
- `Ctrl+C` — kill whatever's currently running in the terminal
- `Ctrl+L` — clear the screen (same as typing `clear`)

## What I got from this

Most of these I already use without thinking, but writing down what each one actually does (instead of just muscle memory) helped for a couple I don't touch often — `du -sh`, `ss`/`netstat` style commands, and the difference between `head`/`tail`/`less`. The `ps aux` vs `ps -eo ...` thing was a good reminder that "just run the example from the cheat sheet" isn't always safe if the output is going somewhere public.
