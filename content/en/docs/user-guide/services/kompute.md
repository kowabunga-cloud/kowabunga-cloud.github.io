---
title: Kompute Virtual Instances
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

## Resource Creation

As a **projectAdmin** user, one can create a **Kompute** virtual machine instance. Example below will spawn a 8 vCPUS, 16 GB RAM, 64 GB OS disk, 128 GB data disk instance, running Ubuntu 24.04 LTS into **acme** project in **eu-west-a** zone.

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
data "kowabunga_zone" "eu-west-a" {
  name = "eu-west-a"
}

resource "kowabunga_kompute" "server" {
  project    = kowabunga_project.acme.id
  name       = "acme-server"
  disk       = 64
  extra_disk = 128
  mem        = 16
  vcpus      = 8
  zone       = data.kowabunga_zone.eu-west-a.id
  template   = "ubuntu-cloudimg-generic-24.04"
}
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

Once created, subscribed users will get notified by email about **Kompute** instance details (such as private IP address, initial bootstrap admin credentials ...).

### DNS Record Association

Any newly created **Kompute** instance will automatically be added into region-local **Kiwi** DNS server. This way, any query to its hostname (*acme-server* in the previous example) will be answered.

Alternatively, you may also be willing to create custom one, for example, as aliases.

Let's suppose you'd like to have previously created instance to be Active-Directory controller, and expose itself as **ad.acme.local** from a DNS perspective. This can be easily done through:

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
resource "kowabunga_dns_record" "ad" {
  project   = kowabunga_project.acme.id
  name      = "ad"
  desc      = "Active-Directory"
  addresses = [resource.kowabunga_kompute.server.ip]
}
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

{{< alert color="success" title="Information" >}}
Note that it is possible to set more than one IP address. If so, the **Kiwi** DNS server will provide all results, to be used as client prefers (usually round-robin policy).
{{< /alert >}}
