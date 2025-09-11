---
title: Provisioning Services
description: Let's provision our services
weight: 7
---

Infrastructure is finally all set. We only need to finalize the setup of a few services (from Kahuna's perspective) and we're done.

## Storage Pool

Let's update your TF configuration to simply declare the following:

```hcl
locals {
  ceph_port          = 3300

  eu-west {
    pools = {
      "eu-west-ssd" = {
        desc    = "SSD"
        secret  = "YOUR_CEPH_FSID",
        cost    = 200.0,
        type    = "rbd",
        pool    = "rbd",
        address = "ceph",
        default = true,
        agents = [
          "kaktus-eu-west-a-1",
          "kaktus-eu-west-a-2",
          "kaktus-eu-west-a-3",
        ]
      },
    }
  }
}

resource "kowabunga_storage_pool" "eu-west" {
  for_each = local.eu-west.pools
  region   = kowabunga_region.eu-west.id
  name     = each.key
  desc     = "${local.eu-west.desc} - ${each.value.desc}"
  pool     = each.value.pool
  address  = each.value.address
  port     = try(each.value.port, local.ceph_port)
  secret   = try(each.value.secret, "")
  price    = try(each.value.cost, null)
  currency = local.currency
  default  = try(each.value.default, false)
  agents   = [for agent in try(each.value.agents, []) : kowabunga_agent.eu-west[agent].id]
}
```

What we're doing here is instructing **Kahuna** that there's a Ceph storage pool that can be used to provision RBD images. It will connect to **ceph** DNS record on port **3300**, and use one of the 3 **agents** defined to connect to pool **rbd**. It'll also arbitrary (as we did for **Katkus** instances) set the global storage pool price to **200 EUR / month**, so virtual resource cost computing can happen.

{{< alert color="warning" title="Warning" >}}
Take care of updating the **YOUR_CEPH_FSID** secret value with the one you've set in Ansible **kowabunga_ceph_fsid** variable. Libvirt won't be able to reach the cluster without this information.
{{< /alert >}}

And apply:

```sh
$ kobra tf apply
```

## NFS Storage

Now if you previously created an NFS endpoint want to expose it through **Kylo** services, you'll also need to setup the following TF resources:

```hcl
locals {
  ganesha_port       = 54934

  eu-west {
      nfs = {
      "eu-west-nfs" = {
        desc     = "NFS Storage Volume",
        endpoint = "ceph.storage.eu-west.acme.local",
        fs       = "nfs",
        backends = [
          "10.50.102.11",
          "10.50.102.12",
          "10.50.102.13",
        ],
        default = true,
      }
    }
  }

}

resource "kowabunga_storage_nfs" "eu-west" {
  for_each = local.eu-west.nfs
  region   = kowabunga_region.eu-west.id
  name     = each.key
  desc     = "${local.eu-west.desc} - ${each.value.desc}"
  endpoint = each.value.endpoint
  fs       = each.value.fs
  backends = each.value.backends
  port     = try(each.value.port, local.ganesha_port)
  default  = try(each.value.default, false)
}
```

In a very same way, this simply instructs **Kahuna** how to access NFS resources and provide **Kylo** services. you must ensure that **endpoint** and **backends** values map to your local storage domain and associated Kaktus instances. They'll be used further by **Kylo** instances to create NFS shares over Ceph.

And again, apply:

```sh
$ kobra tf apply
```

## OS Image Templates

And finally, let's declare OS image templates. Without those, you won't be able to spin up any kind of **Kompute** virtual machines instances after all. Image templates must be ready-to-boot, cloud-init compatible and either in QCOW2 (smaller to download, prefered) or RAW format.

Up to you to use pre-built community images or host your own custom one on a public HTTP server.

{{< alert color="warning" title="Warning" >}}
Note that URL must be reachable from Kaktus nodes, not Kahuna one (so can be private network).

The module however does not support authentication at the moment, so images must be "publicly" available.
{{< /alert >}}

```hcl
locals {
  # WARNING: these must can be in either QCOW2 (recommended) or RAW format
  # Example usage for conversion, if needed:
  # $ qemu-img convert -f qcow2 -O raw ubuntu-22.04-server-cloudimg-amd64.img ubuntu-22.04-server-cloudimg-amd64.raw
  templates = {
    "ubuntu-cloudimg-generic-24.04" = {
      desc    = "Ubuntu 24.04 (Noble)",
      source  = "https://cloud-images.ubuntu.com/noble/20250805/noble-server-cloudimg-amd64.img"
      default = true
    }
  }
}

resource "kowabunga_template" "eu-west" {
  for_each = local.templates
  pool     = kowabunga_storage_pool.eu-brezel["eu-west-ssd"].id
  name     = each.key
  desc     = each.value.desc
  os       = try(each.value.os, "linux")
  source   = each.value.source
  default  = try(each.value.default, false)
}
```

At creation, declared images will be download by one of the **Kaktus** agent and stored into Ceph cluster. After that, one can simply reference them by their name when creating **Kompute** instances.

{{< alert color="warning" title="Warning" >}}
Depending on remote source, image size and your network performance, retrieving images can take a significant amount of time (several minuutes). TF provider is set to use a 30mn timeout by default. Update it accordingly if you believe this won't be enough.
{{< /alert >}}

Congratulations, you're now done with administration tasks and infrastructure provisionning. You now have a fully working Kowabunga setup, ready to be consumed by end users.

Let's then [provision our first project](/docs/user-guide/create-project/) !
