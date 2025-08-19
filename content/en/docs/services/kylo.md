---
title: Kylo
description: Kowabunga Distributed Network File System
weight: 10
---

**Kylo** is Kowabunga's incarnation of NFS. While all **Kompute** instances have their own local block-device storage disks, **Kylo** provides the capability to access a network storage, shared amongst virtual machines.

**Kylo** fully implements the NFSv4 protocol, making it easy for Linux instances (and even Windows) to mount it without any specific tools.

Under the hood, **Kylo** relies on underlying **CephFS** volume, exposed by **Kaktus** nodes, making it natively distributed and resilient (i.e. one doesn't need trying to add HA on top).

{{< alert color="warning" title="Warning" >}}
**Kylo** access is restricted to project's private network. While all your project's instances can mount a **Kylo** endpoint, it can't be reached from the outside.
{{< /alert >}}
