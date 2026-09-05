# Networking Fundamentals

## Task 1 notes

The devops-heros repo's networking session (`session4-networking`) is mostly subnetting theory notes (`ip.md`) rather than a command list — classes of IP addresses (A/B/C/D), subnet masks, how network bits vs host bits work, private IP ranges, that kind of thing. Went through it — the main thing that clicked for me: the subnet mask tells you where the "network part" of an IP ends and the "host part" begins. E.g. a Class A mask `255.0.0.0` means only the first 8 bits are network, so you get 24 host bits = up to 2^24 - 2 usable addresses on that network. The actual commands to run live in the Linux cheat sheet's "Networking Commands" section instead, so that's what I practiced below for Task 2.

## Task 2 — commands run, with what I understood

### `ping`

```
$ ping -c 4 google.com
PING google.com (142.250.207.174) 56(84) bytes of data.
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=1 ttl=116 time=24.5 ms
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=2 ttl=116 time=36.8 ms
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=3 ttl=116 time=22.9 ms
64 bytes from pnbomb-bl-in-f14.1e100.net (142.250.207.174): icmp_seq=4 ttl=116 time=22.9 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 4129ms
rtt min/avg/max/mdev = 22.876/28.605/36.794/5.456 ms
```

Sends ICMP echo requests to check if a host is reachable and how long the round trip takes. `-c 4` limits it to 4 pings instead of running forever. `0% packet loss` = connection to google.com is fine, ~20-35ms latency.

### `ip a`

```
$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet 10.255.255.254/32 brd 10.255.255.254 scope global lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:aa:c2:73 brd ff:ff:ff:ff:ff:ff
    inet 192.168.153.218/20 brd 192.168.159.255 scope global eth0
```

Lists every network interface on the machine and its IP address(es). `lo` is the loopback (127.0.0.1, talks to itself), `eth0` is the actual network adapter WSL uses — `192.168.153.218/20` is its address on the private virtual network WSL sets up between Windows and Linux. The `/20` at the end is the subnet mask in CIDR notation, ties back to the subnetting notes from Task 1.

### `ss` (used instead of `netstat`)

```
$ ss -tulwn
Netid State  Recv-Q Send-Q  Local Address:Port  Peer Address:Port
udp   UNCONN 0      0          127.0.0.54:53         0.0.0.0:*
udp   UNCONN 0      0       127.0.0.53%lo:53         0.0.0.0:*
tcp   LISTEN 0      4096        127.0.0.1:34051      0.0.0.0:*
tcp   LISTEN 0      511         0.0.0.0:6379         0.0.0.0:*
tcp   LISTEN 0      4096       127.0.0.54:53         0.0.0.0:*
```

The cheat sheet lists `netstat -tulnp` for this, but `netstat` isn't even installed on this WSL image — `ss` is the modern replacement (it's literally listed in the same cheat sheet as "faster alternative to netstat"), so used that instead. Shows every port currently listening for connections. `:53` ports are DNS (systemd-resolved), `:6379` is Redis, which I have running locally for something else. `-t` = TCP, `-u` = UDP, `-l` = listening only, `-n` = show raw port numbers instead of resolving service names, `-w` = wide output so nothing gets cut off.

### `curl`

```
$ curl -sI https://api.github.com
HTTP/2 200
date: Sat, 05 Sep 2026 14:48:26 GMT
x-ratelimit-limit: 60
x-ratelimit-remaining: 58
content-type: application/json; charset=utf-8
```

`-I` fetches only the response headers, not the actual body — quick way to check if an API/site is up and what it's telling you (status code, rate limits, content type) without downloading anything. `-s` just silences the progress bar.

### `wget`

```
$ wget -q https://raw.githubusercontent.com/Nency-Ravaliya/devops-heros/main/README.md -O readme-test.md
$ ls -l readme-test.md
-rw-r--r-- 1 sachith sachith 275 Sep  5 14:50 readme-test.md
$ head -3 readme-test.md
# devops-heros

## DevOps HomeWork
```

Grabbed the actual README of the devops-heros repo to test it, and it saved fine. `-q` quiets the progress output, `-O` picks the output filename — difference from `curl` is `wget` is built for saving files, `curl` is built more for inspecting/scripting against APIs.

## What I got from this

Went through the subnetting notes from the shared repo, then ran and understood the actual networking commands (`ping`, `ip a`, `ss`, `curl`, `wget`) instead of just reading what they do.
