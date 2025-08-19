---
title: Overview
description: How can Kowabunga sustain your applications hosting ?
weight: 1
---

## What is it ?

**Kowabunga** is an [SD-WAN](https://en.wikipedia.org/wiki/SD-WAN) and [HCI](https://en.wikipedia.org/wiki/Hyper-converged_infrastructure) (Hyper-Converged Infrastructure) Orchestration Engine.

Market BS aside, Kowabunga provides DevOps with a complete infrastructure automation suite to orchestrate virtual resources management automation on privately-owned commodity hardware.

It brings the best of both worlds:

- Cloud API, automation, infrastructure-as-code, X-as-a-service ...
- On-Premises mastered and predictable flat-rate hardware.

## The Problem

{{% pageinfo %}}
**Cloud Services are unnecessarily expensive and come with vendor-locking.**
{{% /pageinfo %}}

> *"Cloud computing is basically renting computers, instead of owning and operating your own server hardware. From the start, companies that offer cloud services have promised simplicity and cost savings. Basecamp has had one foot in the cloud for well over a decade, and HEY has been running there exclusively since it was launched two years ago. We’ve run extensively in both Amazon’s cloud and Google’s cloud, but the savings promised in reduced complexity never materialized. So we’ve left.*
>
> *The rough math goes like this: We spent $3.2m on cloud in 2022.The cost of rack space and new hardware is a total of **$840,000 per year**.*
>
> ***Leaving the cloud will save us $7 million over five years.***
>
> *At a time when so many companies are looking to cut expenses, saving millions through hosting expenses sounds like a better first move than the rounds of layoffs that keep coming."*
>
> [Basecamp by 37signals](https://basecamp.com/cloud-exit)

## Why Kowabunga ?

- **Cost-Effective**: Full private-cloud on-premises readiness and ability to run on commodity hardware. No runtime fees, no egress charges, flat-rate predictable cost. **Keep control of your TCO.**

- **Resilient & Features-Rich**: Kowabunga enables highly-available designs, across multiple data centers and availability zones and brings automated software-as-a-service. **Shorten application development and setup times.**

- **No Vendor-Locking**: Harness the potential of Open-Source software stack as a backend: no third-party commercial dependency. We stand on the shoulders of giants: KVM, Ceph ... **Technical choices remain yours and yours only.**

- **Open Source … by nature**: Kowabunga itself is OpenSource, from API to client and server-side components. We have nothing to hide but everything to contribute. **We believe in mutual trust.**

**A Kowabunga-hosted project costs 1/10th of a Cloud-hosted one.**

## Why do I want it ?

- **What is it good for?**: Modern SaaS products success are tighly coupled with profitability. As soon as you scale up, you'll quickly understand that you're actually sponsoring your Cloud provider more than your own teams. **Kowabunga** allows you to keep control of your infrastructure and its associated cost and lifecycle. You'll never get afraid of unexpected business model change, tariffs and whatnot. You own your stack, with no surprises.

- **What is it not good for?**: PoC and MVP startups. Let's be realistic, if you're goal is to vibe-code your next million-dollar idea and deliver it, no matter how and what, forget about us. You have other fish to fry than mastering your own infrastructure. Get funded, wait for your investors to ask for RoI, and you'll make your mind.

- **What is it _not yet_ good for?**: Competing with GAFAM. Let's be honest, we'll never be the next AWS or GCP (or even OpenStack). We'll never have 200+ as-a-service kind of stuff, but how many people actually need that much ?

## Is it business-ready ?

Simply put ... **YES !**

Kowabunga allows you to host and manage personal labs, SOHO sandboxes, as well as million-users SaaS projects. Using Open Source software doesn't imply living on your own. Through our sponsoring program, Kowabunga comes with 24x7 enterprise-grade level of support.

## Fun Facts 🍿

Where does it comes from ? Everything comes as a solution to a given problem.

Our problem was (and still is ...) that Cloud services are unnecessarily expensive and often come with vendor-locking.
While Cloud services are appealing at first and great to bootstrap your project to an MVP level, you'll quickly hit profitability issues when scaling up.

Provided you have the right IT and DevOps skills in-house, self-managing your own infrastructure makes sense at economical level.

Linux and QEMU/KVM comes in handy, especially when powered by libvirt but we lacked true resource orchestration to push it to next stage.

OpenStack was too big, heavy, and costly to maintain. We needed something lighter, simpler.

So we came with **Kowabunga**: **K**vm **O**rchestrator **W**ith **A** **BUN**ch of **G**oods **A**dded.

## Where should I go next ?

- [Concepts](/docs/concepts/): Lear about Kowabunga architecture and design
- [Getting Started](/docs/getting-started/): Get started with Kowabunga
