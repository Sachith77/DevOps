# Docker Multi-Stage Build Homework

**Name:** Sachith Reddy
**Enrollment Number:** _fill in_

## Task 1: Run Multi-Stage Dockerfile

The `Dockerfile`, `package.json`, and `server.js` in this folder are copied straight from the `multi-stage-dockerfile` folder in the devops-heros repo (`session6-7-docker/multi-stage-dockerfile`) — didn't modify the Dockerfile itself, just changed the port mapping at run time to satisfy the "must run on port 8080" requirement (the app listens on 3000 internally).

```bash
docker build -t multistage-hello .
docker run -d --name multistage-hello -p 8080:3000 multistage-hello
```

## Task 2: Output evidence

### Application output

```
$ curl -s http://localhost:8080
<h1>Hello World from Docker Multi-Stage Build!</h1>
```

Matches the required "Hello World from Docker multi-stage build" text.

### docker ps on port 8080

```
$ docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
NAMES               IMAGE               PORTS                                          STATUS
multistage-hello    multistage-hello    0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp    Up 2 seconds
```

Confirms the container is running with host port `8080` mapped to the app.

## Task 3: Docker Application Deployment (3+ app types)

Already covered in `05-docker-fundamentals/` — deployed Node.js, Python, and Java apps with Docker there (plus Apache, React, and Nginx). See that folder for each Dockerfile and build/run/verify output.
