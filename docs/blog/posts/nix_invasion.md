---
date: 2025-03-24
authors:
  - deepak
categories:
  - tech
tags:
  - nix
description:
    - How nix has invaded my life
title: Nix Invasion
---

# Nix Invasion

This blog post will detail my introduction to nix and describe how I am using it today, if you are a software engineer frustrated with setting up environments or a distro hopper who is finally done with finding installation instructions for software in every distro and asking ChatGPT for help when they do not work this blog will convince you to learn nix.

<!-- more -->

## Intro

For a long time I was working on a code execution engine based on docker but I abandoned it as I felt that configuring and maintaining docker images would take a lot of effort and space and when I was exploring what project I would work on next I think I heard the word nix from a blog or reddit comment and decieded to give it a try.

## Beginning

I naively thought that this would be a replacement for brew or apt but as I started reading the docs I realised that it was going to take me a lot of time to understand everything about nix when I learned that nix is based on the [PHD thesis](https://edolstra.github.io/pubs/phd-thesis.pdf) written by Eelco Dolstra (the creator of nix). 

Every blog post and documentation section I read described 5 different ways to do the same thing (there are two ways of just installing nix on linux). On top of that there were a lot of concepts that I had to learn and understand how they work. I gave up on learning nix a lot of times but I went back everytime beacuse of what nix promised. I found this brilliant [blog](https://ianthehenry.com/posts/how-to-learn-nix/introduction/) by [Ian henry](https://ianthehenry.com/) that helped me a lot.

## Experimenting And Learning

I started experimenting with every command and concept that I could use and I started to see the bigger picture of what nix is about. Once I was able to get an overview of the entire ecosystem of nix it became much clearer and I was able to create what I exactly wanted using nix.

I started learning about shells, flakes, packaging, home-manager and tests and it completely transformed the way I setup environments for my projects and package them and the full scale invasion of nix started.

## The Power Of The Sun In The Palm Of My Hands

I now explicitly use nix in almost all of my go, python and typescript projects for creating a development enviornment and packaging projects. To quickly try out any new tool that I want to try I create nix-shells or use flakes and I manage my entire system config with home-manager.

I can't even remember the last time I checked the installation instructions for installing any of the applications I use on a regular basis. I just keep changing my home-manager config to use a different shell or a different editor wihout worrying if I have messed up my dotfiles or I have not proprely uninstalled something.

## Final Thoughts

Learning nix takes time and patience but the end result is well worth it. Feel free to give it a try, if you face any issues don't hesitate to hit me up.