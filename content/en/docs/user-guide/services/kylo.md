---
title: Kylo NFS
description: Kowabunga Distributed Network File System
weight: 10
---

**Kylo** is Kowabunga's incarnation of NFS. While all **Kompute** instances have their own local block-device storage disks, **Kylo** provides the capability to access a network storage, shared amongst virtual machines.

**Kylo** fully implements the NFSv4 protocol, making it easy for Linux instances (and even Windows) to mount it without any specific tools.

Under the hood, **Kylo** relies on underlying **CephFS** volume, exposed by **Kaktus** nodes, making it natively distributed and resilient (i.e. one doesn't need trying to add HA on top).

{{< alert color="warning" title="Warning" >}}
**Kylo** access is restricted to project's private network. While all your project's instances can mount a **Kylo** endpoint, it can't be reached from the outside.
{{< /alert >}}

## Resource Creation

As a **projectAdmin** user, one can create a **Kylo** etwork file-system instance. Example below will spawn a instance named **acme-nfs** in **eu-west** region for project **acme**.

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
data "kowabunga_region" "eu-west" {
  name = "eu-west"
}

resource "kowabunga_kylo" "nfs" {
  project = kowabunga_project.acme.id
  region  = data.kowabunga_region.eu-west.id
  name    = "acme-nfs"
  desc    = "ACME NFS share"
}
}
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

{{< alert color="success" title="Information" >}}
Kylo features virtually unlimited storage. It can grow as big as your underlying Ceph cluster can.
{{< /alert >}}
