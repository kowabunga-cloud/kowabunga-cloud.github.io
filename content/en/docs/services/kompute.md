---
title: Kompute
description: Kowabunga Virtual Machine instance
weight: 6
---

Kowabunga **Kompute** is the incarnation of a virtual machine instance.

Associated with underlying distributed block storage, it provides everything one needs to run generic kind of application workload.

**Kompute** instance can be created (and further edited) with complete granularity:

- number of virtual CPU cores.
- amount of virtual memory.
- one OS disk and any number of extra data disks.
- optional public (i.e. Internet) direct exposure.

Compared to major Cloud providers who will only provide pre-defined machine flavors (with X vCPUs and Y GB of RAM), you're free to address machines to your exact needs.

**Kompute** instances are created and bound to a specific region and zone, where they'll remain. Kahuna orchestration will make sure to instantiate the requested machine on the the best **Kaktus** hypervisor (at the time), but thanks to underlying distributed storage, it can easily migrate to any other instance from the specified zone, for failover or balancing.

**Kompute**'s OS disk image is cloned from one of the various OS templates you'll have provided Kowabunga with and thanks to thin-provisioning and underlying copy-on-write mechanisms, no disk space is ever redeemed. Feel free to allocate 500 GB of disk, it'll never get consumed until you actually store data onto !

Like any other service, **Kompute** instances are bound to a specific project, and consequently associated subnet, making it sealed from other projects' reach. Private and public interfaces IP addresses are automatically assigned by Kahuna, as defined by administrator, making it ready to be consumed for end-user.
