---
date: 2025-07-24
authors:
  - deepak
categories:
  - tech
tags:
  - nix
description:
  - Speeding up nix scripts and nix-shell with caching
title: Cached Nix Shell - Speed Up Your Nix Workflows
---

## Intro

Nix offers a way to create and run reproducible interpreted scripts. At [Valkyrie](https://github.com/deepakdinesh1123/valkyrie), we use this to safely execute user-submitted code inside containers. While Nix provides excellent reproducibility, the startup time can be frustratingly slow. When optimizing our execution pipeline, I discovered the Cached Nix Shell project, which has been a game-changer for our performance.

<!-- more -->

## What is Cached Nix Shell?

[Cached Nix Shell](https://github.com/xzfc/cached-nix-shell) is a project by [xzfc](https://github.com/xzfc) that addresses the startp time of nix shells by caching environment variables set by nix-shell. This significantly reduces startup time for scripts that use the same dependencies across multiple runs.

## How it works

1. It stores the environment variables created by nix-shell during the first run
2. On subsequent executions, it reuses these cached variables instead of re-evaluating everything
3. It employs the `LD_PRELOAD` technique to track all files accessed during the evaluation phase
4. This tracking enables proper cache invalidation if any inputs have changed

This approach gives you the best of both worlds: Nix's reproducibility with improved performance.

## Installation

```shell
nix-env -iA nixpkgs.cached-nix-shell
```

## Usage

```bash
#! /usr/bin/env cached-nix-shell
#! nix-shell -i bash
#! nix-shell -p go

go version
```

The first run will take the usual amount of time, but subsequent runs will be fast as long as your dependencies haven't changed.

## Limitations

Unfortunately, I discovered that cached-nix-shell doesn't work properly with language environments that bundle multiple packages. For example:

```bash
#! nix-shell -p 'python3.withPackages(p: [p.django])'  # This fails with cached-nix-shell
```

This limitation affects workflows with Python, Ruby, and similar language environments that need dependencies.

## My Solution

I decided to fork the project and patch it to support language environments. I've used my Rust skills to modify the implementation to handle these more complex package structures.

My fork is still in testing, but I plan to submit a pull request to the original project once I've verified everything works as expected. If you're encountering the same issues, you can try out my patched version:

```shell
nix-env -if https://github.com/deepakdinesh1123/cached-nix-shell/tarball/master
```

I'd love to hear your feedback if you give it a try!