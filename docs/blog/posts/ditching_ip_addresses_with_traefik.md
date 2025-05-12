---
date: 2025-05-24
authors:
  - deepak
categories:
  - tech
tags:
  - traefik
  - docker
description:
  - Clean URLs for Valkyrie Sandboxes
title: Clean URLs for Valkyrie Sandboxes
---

## Intro

[Valkyrie](https://github.com/deepakdinesh1123/valkyrie) offers sandboxes, isolated dev and test environments that can be configured using Nix flakes and controlled via a Python SDK.

<!-- more -->

## Problem

After adding support for sandboxes, we ran into an annoying problem. The URLs used to access them looked like this: `http://192.168.1.1:9090/sandbox`. These IP-based URLs were hard to remember and use.

I started exploring solutions, but most of them required users to make system-level changes like modifying `/etc/hosts` or running local DNS servers. That kind of setup added complexity and friction we didn’t want. Then I stumbled upon [Dokploy](https://dokploy.com/), and while browsing their docs, I found a simple and elegant solution.

## Traefik to the Rescue

[Traefik](https://traefik.io/traefik/) is an open-source application proxy that automatically discovers and routes traffic to your services. No need to maintain static config files, it integrates directly with Docker, Kubernetes, and other orchestration tools to pick up routing rules on the fly.

This was exactly what we needed.

## The Fix

Here’s how we solved it:

We created a shared Docker network that both Traefik and our sandbox containers use. Then, using Docker labels, we configured Traefik to route traffic based on container names.

Here’s a sample `docker-compose` config:

```yaml
services:
  service1:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<service_name>.rule=Host(`<service_name>.localhost`)"
      - "traefik.http.routers.<service_name>.entrypoints=http"
      - "traefik.http.routers.<service_name>.service=<service_name>"
      - "traefik.http.services.<service_name>.loadbalancer.server.port=9090"
```
You can customize the hostname, choose entrypoints, and even expose multiple services within the container using different load balancer rules.

Now, instead of hard-to-remember IP-based URLs like:
```
http://192.168.1.1:9090/sandbox
```

We get much cleaner and more intuitive ones like:
```
http://pensive-pike.localhost/sandbox
```

Way easier to remember and use.

This tiny tweak, powered by Traefik and a few Docker labels, dramatically improved the UX for working with Valkyrie sandboxes.

You can also use this to avoid publishing container ports to host port and run two instances of postgres easily without having to use two different ports

## Bonus

- If you already use caddy as your proxy you can check out [Caddy Docker Proxy](https://github.com/lucaslorentz/caddy-docker-proxy) which offers a similar solution.
