---
date: 2025-05-22
authors:
  - deepak
categories:
  - tech
tags:
  - nix
  - docker
description:
  - Speeding up docker builds at valkyrie
title: Speeding Up Docker Builds At Valkyrie
---

## Intro

At [Valkyrie](https://github.com/deepakdinesh1123/valkyrie), we build the valkyrie and the agent docker images using Nix. This works well since all the dependencies are declared using nix and we use multi stage build, ensuring the final image only contains the packages required. We decided not to use the nix docker builder due to some issues we faced. However our approach started showing its own problems.

<!-- more -->

## Problem

The Dockerfile to build Valkyrie originally looked like this:

```dockerfile
FROM nixos/nix:2.24.0 AS builder

RUN mkdir -p /etc/nix && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

WORKDIR /valkyrie
COPY flake.nix /valkyrie
COPY flake.lock /valkyrie
RUN nix develop --command 'ls' # cache packages to avoid downloading everytime you change the code

COPY cmd /valkyrie/cmd
COPY builds/nix/valkyrie.nix /valkyrie/builds/nix/valkyrie.nix
COPY internal /valkyrie/internal
COPY pkg /valkyrie/pkg
COPY go.mod /valkyrie
COPY go.sum /valkyrie

RUN nix build # Build valkyrie using nix

RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure # copy the closure to a folder

FROM ubuntu:24.04

RUN apt update && \
    apt install -y adduser curl xz-utils && \
    groupadd -o -g 1024 -r valnix && \
    adduser --uid 1024 --gid 1024 --disabled-password --gecos "" valnix

COPY --from=builder /tmp/nix-store-closure /nix/store # Copy the closure to the nix store
COPY --from=builder /valkyrie/result /home/valnix # Copy the result folder which contains a symlink to the valkyrie binary

USER valnix
WORKDIR /home/valnix
ENTRYPOINT ["/home/valnix/bin/valkyrie"]
```

Although this can be improved a lot, the immediate problem we started noticing was the build speed and cache utilization. If we modified the `flake.nix` file in any way (even for changes unrelated to Valkyrie or the agent itself), Docker's layer cache was invalidated and we had to download all the Nix packages and rebuild everything again. This often took a significant amount of time, especially when the Nix binary cache didn't respond quickly. During active development, we were hitting the Nix cache far too often, which was inefficient and extremely bad.

## Docker Mount Cache to the Rescue

While going through a video about using Docker and Nix ([link](https://www.youtube.com/watch?v=l17oRkhgqHE&t=2467s)), I saw a Dockerfile that utilized a `--mount=type=cache`. Digging further, I came across Docker's mount cache([link](https://docs.docker.com/build/cache/optimize/#use-cache-mounts))

from the docker docs

> Cache mounts are a way to specify a persistent cache location to be used during builds. The cache is
> cumulative across builds, so you can read and write to the cache multiple times. This persistent caching
> means that even if you need to rebuild a layer, you only download new or changed packages. Any unchanged
> packages are reused from the cache mount.


This was exactly what we needed to solve our problem.

## The Fix

Here’s how we implemented it:

We modified the main `RUN nix build ...` step in our builder stage to use the `--mount=type=cache` with the `/nix` directory as the target. This makes sure that the Nix store is cached between Docker build invocations.

The final Dockerfile with this implemented looks like this:

```dockerfile
FROM nixos/nix:2.24.0 AS builder

WORKDIR /valkyrie
COPY flake.nix /valkyrie
COPY flake.lock /valkyrie

COPY cmd /valkyrie/cmd
COPY builds/nix/valkyrie.nix /valkyrie/builds/nix/valkyrie.nix
COPY internal /valkyrie/internal
COPY pkg /valkyrie/pkg
COPY go.mod /valkyrie
COPY go.sum /valkyrie

RUN \
    --mount=type=cache,target=/nix,from=nixos/nix:2.24.0,source=/nix \
    mkdir -p /tmp/nix-store-closure  && \
    nix \
    --extra-experimental-features "nix-command flakes" \
    --option filter-syscalls false \
    --show-trace \
    --log-format raw \
    build --out-link /tmp/valkyrie/result && \
    cp -R $(nix-store -qR /tmp/valkyrie/result) /tmp/nix-store-closure

FROM ubuntu:24.04

RUN apt update && \
    apt install -y adduser curl xz-utils && \
    groupadd -o -g 1024 -r valnix && \
    adduser --uid 1024 --gid 1024 --disabled-password --gecos "" valnix

COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/valkyrie/ /home/valnix

COPY --chown=valnix:valnix rippkgs-24.11.sqlite /home/valnix/.valkyrie_info/
RUN chown -R valnix:valnix /home/valnix/.valkyrie_info/

USER valnix
WORKDIR /home/valnix
ENTRYPOINT ["/home/valnix/result/bin/valkyrie"]
```

With the `--mount=type=cache,target=/nix,...` directive, the contents of the `/nix/store` are persisted across Docker builds. When `nix build` runs, it can find most, if not all, dependencies in this locally persisted cache.

## Impact

While I cannot exactly quantify the build time improvement since it depended heavily on how fast the Nix binary cache responded at any given moment, I can safely say that the build time was **noticeably faster**. Crucially, we were not hitting the Nix binary cache nearly as much as we used to.

This change significantly improved our development speed and reduced our usage of the nix binary cache.
