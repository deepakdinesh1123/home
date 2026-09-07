---
date: 2026-09-07
authors:
  - deepak
categories:
  - tech
tags:
  - docker
description:
  - How to use extra_hosts in docker compose to simplify your setup
title: How to use extra_hosts in docker compose to simplify your setup
---

## Intro

When working on simplifying the analytics setup in my django app (you can read the article about it [here](https://deepakdinesh1123.github.io/home/blog/2026/09/06/adding-an-analytics-dashboard-to-your-application-without-losing-your-sanity-or-money/)), to store the parquet files I wanted to use [django-storages](https://django-storages.readthedocs.io/en/latest/) with S3 as a storage backend. The straightforward solution was to use an actual S3 bucket but I did not want to make that a hard requirement so that it's easier for someone else to set up and use it.

<!-- more -->

## S3 on your machine

There are several ways to run S3 locally but one of the easiest and most convenient is [Minio](https://github.com/minio/minio) (although its community edition is now killed in favour of the business edition so it's better to use alternatives). I set up a minio service and started running it locally to upload my parquet files.

```yaml
services:
  django:
    build:
      context: .
    command: uv run python examples/dj/manage.py runserver 0.0.0.0:8000
    ports:
      - "8000:8000"
    environment:
      AWS_ACCESS_KEY_ID: minioadmin
      AWS_SECRET_ACCESS_KEY: minioadmin123
      AWS_STORAGE_BUCKET_NAME: duckgraph
      AWS_STATIC_STORAGE_BUCKET_NAME: duckgraph-static
      AWS_S3_ENDPOINT_URL: http://minio:9000
      AWS_S3_REGION_NAME: us-east-1
      AWS_S3_ADDRESSING_STYLE: path
    depends_on:
      - minio

  minio:
      image: quay.io/minio/minio
      command: server /data --console-address ":9001"
      environment:
        MINIO_ROOT_USER: minioadmin
        MINIO_ROOT_PASSWORD: minioadmin123
        MINIO_API_CORS_ALLOW_ORIGIN: "http://localhost:8000,http://127.0.0.1:8000"
      ports:
        - "9000:9000"
        - "9001:9001"
```

Due to the way networking works in Docker this quickly started causing a problem. My django service could only access Minio through the URL `http://minio:9000` since Docker services don't have access to Docker's internal DNS from the host and rely on the name of the service to resolve the IP address through Docker's DNS. The browser, on the other hand, could not access the URL `http://minio:9000/duckgraph/file.parquet` since it did not know how to resolve the host `minio` to the IP address of the service.

The problem is that `minio` is a Docker service name. It works from another container on the same Docker network, but it does not mean anything to the browser running on the host machine.

A hacky solution would be to replace the host in the URL returned by django-storages to `http://localhost:9000` to allow the browser to access it but I wanted a cleaner solution without overly complicating my setup.

## Extra hosts

The idea is to use a hostname that works both from the browser and from inside the Docker container.

```yaml
services:
  django:
    ...

    environment:
      ...
      AWS_S3_ENDPOINT_URL: http://minio.localhost:9000
      ...

    extra_hosts:
      - "minio.localhost:host-gateway"
```

`extra_hosts` adds a hostname-to-IP mapping to the `/etc/hosts` file inside the container. In this case, `host-gateway` points `minio.localhost` to the Docker host, allowing the django container to access the Minio service through the port published on the host.

The interesting part is that `minio.localhost` also works from the browser. `.localhost` hostnames resolve to the local machine, so the browser can access `http://minio.localhost:9000` through the port we exposed earlier.

This means both the django container and the browser can use the exact same URL:

```text
http://minio.localhost:9000/duckgraph/file.parquet
```

From the django container the request goes roughly like this:

```text
Django container
      |
      | minio.localhost
      v
host-gateway
      |
      | :9000
      v
Minio container
```

And from the browser:

```text
Browser
      |
      | minio.localhost
      v
localhost
      |
      | :9000
      v
Minio container
```

This means django-storages can generate the URL normally without us having to rewrite the hostname depending on where the URL is going to be used.

Another option would be to configure django-storages with different endpoints for talking to S3 and generating URLs. However, for my setup I wanted to keep the same endpoint everywhere and avoid having separate internal and external URL configuration, so extra_hosts gives me a simple way to make minio.localhost work in both places.
