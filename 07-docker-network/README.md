# Docker Networking & Volume Homework

## Task 1: Docker Container Networking

Created 3 containers (frontend = nginx, backend = alpine, database = mysql) and 3 separate networks, then connected backend to 2 of them.

```bash
docker network create net-frontend
docker network create net-backend
docker network create net-database

docker run -d --name frontend --network net-frontend nginx:alpine
docker run -d --name database --network net-database -e MYSQL_ROOT_PASSWORD=rootpass mysql:8.0
docker run -d --name backend --network net-frontend alpine:latest sleep infinity

docker network connect net-backend backend
```

Confirmed backend is actually on 2 networks:
```
$ docker inspect backend --format '{{json .NetworkSettings.Networks}}' | tr ',' '\n' | grep -i networkid
"NetworkID":"0e694aa9df64b1ad89805abe43a8762f6b9c103e28f0d73bef929b71e49d3b3e"
"NetworkID":"9c36534073434ab36eff7abacf9bcab898cfb9d2965eab784826b6b0fbeef035"
```

### Connectivity check

`backend` and `frontend` share `net-frontend`, so they can reach each other:
```
$ docker exec backend ping -c 2 frontend
PING frontend (172.20.0.2): 56 data bytes
64 bytes from 172.20.0.2: seq=0 ttl=64 time=2.483 ms
64 bytes from 172.20.0.2: seq=1 ttl=64 time=0.163 ms
--- frontend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

`backend` is NOT on `net-database`, so it can't resolve/reach `database` at all:
```
$ docker exec backend ping -c 2 database
ping: bad address 'database'
```

To prove this is purely about shared networks (not something wrong with `database`), connected `frontend` to `net-database` too and it worked immediately:
```
$ docker network connect net-database frontend
$ docker exec frontend ping -c 2 database
PING database (172.22.0.2): 56 data bytes
64 bytes from 172.22.0.2: seq=0 ttl=64 time=0.285 ms
64 bytes from 172.22.0.2: seq=1 ttl=64 time=0.276 ms
--- database ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

Take away: Docker network isolation is real — two containers can only talk to each other if they share at least one network, regardless of what else is running.

## Task 2: Host Network

```bash
docker run -d --name apache-host --network host httpd:alpine
```

First attempt failed — `curl http://localhost:80` from both WSL and Windows came back with nothing / connection refused, even though `docker exec apache-host curl localhost:80` worked fine *inside* the container. Turns out Docker Desktop on Windows needs an explicit **"Host networking"** toggle enabled (Docker Desktop → Settings → Resources → Network) for `--network host` to actually bind to something reachable from outside the container — without it, host networking silently attaches to Docker Desktop's internal VM namespace instead of anything you can actually reach. Enabled that setting, restarted Docker Desktop (which stops all running containers), then started the container back up:

```bash
docker start apache-host
```

```
$ curl -s http://localhost:80
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>

$ docker ps --filter name=apache-host --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
NAMES         IMAGE          PORTS     STATUS
apache-host   httpd:alpine             Up 20 seconds
```

Notice the `PORTS` column is empty — that's the tell for host networking, since the container isn't mapping any port, it's just directly using the host's own network stack, so Apache's default port 80 is the host's port 80.

## Task 3: Bind Mount

```bash
mkdir -p bind-mount-demo/html
# wrote index.html with <h1>Hello students</h1> into it
docker run -d --name bind-mount-nginx -p 8084:80 \
  -v /mnt/d/DevOps/07-docker-network/bind-mount-demo/html:/usr/share/nginx/html \
  nginx:alpine
```

Before editing anything:
```
$ curl -s http://localhost:8084
<h1>Hello students</h1>
```

Edited `bind-mount-demo/html/index.html` directly on the host (not inside the container) to say "Hello students - updated live via bind mount!", then re-checked without touching the container at all:
```
$ docker ps --filter name=bind-mount-nginx --format 'table {{.Names}}\t{{.Status}}'
NAMES              STATUS
bind-mount-nginx   Up 19 seconds

$ curl -s http://localhost:8084
<h1>Hello students - updated live via bind mount!</h1>
```

Container uptime shows it was never restarted, but the new content is served instantly — that's the point of a bind mount: the container reads straight from the host folder, there's no copy baked into the image.

## Task 4: Overlay Network

An overlay network lets containers on **different Docker hosts** (different physical/virtual machines) talk to each other as if they were on the same network — Docker handles routing traffic between the hosts underneath (it wraps container traffic in VXLAN and sends it over the hosts' existing network). Real use case: a Swarm or multi-host cluster where a container on host A needs to reach a container on host B by name, without manually managing routes.

Tried creating one directly, without any Swarm setup, to see what happens:
```
$ docker network create -d overlay test-overlay
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again.
```

So overlay networks specifically require Swarm mode — makes sense, since Swarm is what tracks which hosts exist and coordinates the network across them. Initialized a (single-node) swarm just to prove the driver actually works:
```
$ docker swarm init
Swarm initialized: current node is now a manager.

$ docker network create -d overlay demo-overlay
$ docker network ls --filter driver=overlay
NETWORK ID     NAME           DRIVER    SCOPE
1vney1lpy1uh   demo-overlay   overlay   swarm
82hp0kxxs8dg   ingress        overlay   swarm
```

`SCOPE` shows `swarm` instead of `local` — different from every bridge network created earlier, confirming this network type is designed to span multiple hosts, not just the one machine. Since I only have one machine to test on, I can't actually show two hosts reaching each other over it — but the mechanism (Swarm-managed, cross-host by design) is what's different from the `bridge` networks used in Task 1.

Cleaned up right after (removed the network, left swarm mode) so as not to leave my Docker Desktop permanently converted into swarm mode:
```
$ docker network rm demo-overlay
$ docker swarm leave --force
Node left the swarm.
```

## Done

All 4 exercises completed and verified with real output above — including a couple of things that didn't work on the first try (the cross-network ping, the host-networking setting), which ended up being more useful to understand than if everything had just worked immediately.
