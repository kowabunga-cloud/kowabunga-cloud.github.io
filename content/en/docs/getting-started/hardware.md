---
title: Hardware Requirements
description: Prepare hardware for setup
weight: 1
---

Setting up a Kowabunga platform requires you to provide the following hardware:

- 1x Kahuna instance (more could used if high-availability is expected).
- 1x Kiwi instance per-region (2x recommended for production-grade)
- 1x Kaktus instance per-region (a minimum of 3x recommended for production-grade, can scale to N).

{{< alert color="warning" title="Important" >}}
Note that while it should work on any kind of Linux distribution, Kowabunga has only been tested (understand it as supported) with Ubuntu LTS. Kowabunga comes pre-packaged for Ubuntu.
{{< /alert >}}

## Kahuna Instance

**Kahuna** is the only instance that will be exposed to end users. It is recommended to have it exposed on public Internet, making it easier for DevOps and users to access to but there's no strong requirement for that. It is fairly possible to keep it local to your private corporate network, only accessible from on-premises network or through VPN.

Hardware requirements are lightweight:

- 2-cores vCPUs
- 4 to 8 GB RAM
- 64 GB for OS + MongoDB database.

Disk and network performance is fairly insignificant here, anything modern will do just fine.

We personnally use and recommend using small VPS-like public Cloud instances. They come with public IPv4 address and all that one needs for a monthly price of $5 to $20 only.

## Kiwi Instance

**Kiwi** will act as a network software router and gateway. Even more than for **Kahuna**, you don't need much horse-power here. If you plan on setting your own home labs, a small 2 GB RAM Raspberry Pi would be sufficient (keep in mind that SoHo routers and gateways are lightweight than that).

If you intend to use it for enteprise-grade purpose, just pick the lowest end server you could fine.

It's probably going to come bundled with 4-cores CPU, 8 GB of RAM and whatever SSD and in any cases, it would be more than necessary, unless you really intend to handle 1000+ computing nodes being a multi-Gbps traffic.

## Kaktus Instance

**Kaktus** instance are another story. If there's one place you need to put your money on, here would be the place. The instance will handle as many virtual machines as can be and be part of the distributed Ceph storage cluster.

Sizing depends on your expected workload, there's no accurate rule of thumb for that. You'll need to think capacity planning ahead. How much vCPUs do you expect to run in total ? How many GBs of RAM ? How much disk ? What overcommit ratio do you expect to set ? How much data replication (and so ... resilience) do you expect ?

These are all good questions to be asked. Note that you can easily start low with only a few **Kaktus** instances and scale up later on, as you grow. The various **Kaktus** instances from your fleet may also be heterogeneous (to some extent).

As a rule of thumb, unless you're doing setting up a sandbox or home lab, a minimum of 3 **Kaktus** instance would be recommended. This allows you to move workload from one to another, or simply put one in maintenance mode (i.e. shutdown workload) while keeping business continuity.

Supposing you have X **Kaktus** instances and expect up to Y to be down at a given time, the following applies:

> **Instance Maximum Workload**: (X - Y) / X %

Said differently, with only 3 machines, don't go above 66% average load usage or you won't be able to put one in maintenance without tearing down application.

Consequently, with availability in mind, better have more lightweight instances than few heavy ones.

Same applies (even more to Ceph storage cluster). Each instance local disk will be part of Ceph cluster (a [Ceph OSD](https://docs.ceph.com/en/latest/man/8/ceph-osd/) to be accurate) and data will be spread across those, from the same region.

Now, let's consider you want to achieve 128 TB usable disk space. At first, you need to define your replication ratio (i.e. how many time objects storage fragments will be replicated across disks). We recommend a minimum of 2, and 3 for production-grade workloads. That means you'll actually need a total of 384 TB of physical disks.

Here are different options to achieve it:

- 1 server with 24x 16TB SSDs
- 3 servers with 8x 16TB SSDs
- 3 servers with 16x 8TB SSDs
- 8 servers with 6x 8TB SSDs
- [...]

From a purely resilient perspective, last option would be the best. It provides the more machines, with the more disks, meaning that if anything happens, the smallest fraction of data from the cluster will be lost. Lost data is possibly only ephemeral (time for server or disk to be brought up again). But while down, Ceph will try to re-copy data from duplicated fragments to other disks, inducing a major private network bandwidth usage. Now whether you only have 8 TB of data to be recovered or 128 TB may have a very different impact.

Also, as your virtual machines performance will be heavily tight to underlying network storage, it is vital (at least for production-grade workloads) to use NVMe SSDs with 10 to 25 Gbps network controllers and sub-millisecond latency between your private region servers.

So let's recap ...

Typical **Kaktus** instances for home labs or sandbox environments would look like:

- 8-cores (16-threads) CPUs.
- 32 GB RAM.
- 2x 1TB SATA or NVMe SSDs (shared between OS partition and Ceph ones)
- 1 Gbps NIC

While **Kaktus** instances for production-grade workload could easily look like:

- 32 to 128 cores CPUs.
- 128 GB to 1.5 TB RAM.
- 2x 256 GB SATA RAID-1 SSDs for OS.
- 6 to 12x 2-8 TB NVMe SSDs for Ceph.
- 10 to 25 Gbps NICs with link-agregation.

{{< alert color="warning" title="Important" >}}
Remember that you can start low and grow later on. All instances must not need to be alike (you can perfectly have "small" 32-cores servers and higher 128-cores ones). But completely heterogenous instances (especially on disk and network constraints) could have disastrous effects.

Keep in mind that all disks form all instances will be part of the same Ceph cluster, where any virtual machine instance can read and write data from. Mixing 25 Gbps network servers with fast NVMe SSDs with low-end 1 Gbps one with rotational HDDs would lower down your whole setup.
{{< /alert >}}
