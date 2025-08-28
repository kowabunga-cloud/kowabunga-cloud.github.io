---
title: Create Your First Region
description: Let's setup a new region and its Kiwi and Kaktus instances
weight: 6
---

Orchestrator being ready, we can now boostrap our first region.

Let's take the following assumptions for the rest of this tutorial:

- The Kowabunga region is to be called **eu-west**.
- The region will have a single zone named **eu-west-a**.
- It'll feature 2 **Kiwi** and 3 **Kaktus** instances.

Back on the TF configuration, let's use the following:

## Region and Zone

```hcl
locals {
  eu-west = {
    desc = "Europe West"

    zones = {
      "eu-west-a" = {
        id = "A"
      }
    }
  }
}

resource "kowabunga_region" "eu-west" {
  name = "eu-west"
  desc = local.eu-west.desc
}

resource "kowabunga_zone" "eu-west" {
  for_each = local.eu-west.zones
  region   = kowabunga_region.eu-west.id
  name     = each.key
  desc     = "${local.eu-west.desc} - Zone ${each.value.id}"
}
```

And apply:

```sh
$ kobra tf apply
```

Nothing really complex here to be fair, we're just using **Kahuna**'s API to register the region and its associated zone.

## Kiwi Instances and Agents

Now, we'll register the 2 **Kiwi** instances and 3 **Kaktus** ones. Please note that:

- we'll extend the TF **locals** definition for that.
- **Kiwi** is to be associated to the global region.
- while **Kaktus** is ti be associated to the region's zone.

Let's start by registering one Kiwi and 2 associated agents:

```hcl
locals {
  eu-west = {

    agents = {
      "kiwi-eu-west-1" = {
        desc = "Kiwi EU-WEST-1 Agent"
        type = "Kiwi"
      }
      "kiwi-eu-west-2" = {
        desc = "Kiwi EU-WEST-2 Agent"
        type = "Kiwi"
      }
    }

    kiwi = {
      "kiwi-eu-west" = {
        desc   = "Kiwi EU-WEST",
        agents = ["kiwi-eu-west-1", "kiwi-eu-west-2"]
      }
    }
  }
}

resource "kowabunga_agent" "eu-west" {
  for_each = merge(local.eu-west.agents)
  name     = each.key
  desc     = "${local.eu-west.desc} - ${each.value.desc}"
  type     = each.value.type
}

resource "kowabunga_kiwi" "eu-west" {
  for_each = local.eu-west.kiwi
  region   = kowabunga_region.eu-west.id
  name     = each.key
  desc     = "${local.eu-west.desc} - ${each.value.desc}"
  agents   = [for agent in try(each.value.agents, []) : kowabunga_agent.eu-west[agent].id]
}
```

{{< alert color="warning" title="Warning" >}}
Note that, despite have 2 **Kiwi** instances, from Kowabunga perspective, we're only registering one. This is because, the 2 instances are only used for high-availability and failover perspective. From service point of view, the region only has one single network gateway.

Despite that, each instance will have its own agent, to establish a WebSocket connection to **Kahuna** orchestrator.
{{< /alert >}}

## Kaktus Instances and Agents

Let's continue with the 3 **Kaktus** instances declaration and their associated agents. Note that, this time, instances are associated to the zone itself, not the region.

{{< alert color="success" title="Information" >}}
Note that **Kaktus** instance creaion/update takes 4 specific parameters into account:
- **cpu_price** and **memory_price** are purely arbitrary values that express how much actual money is worth your metal infrastructure. These are used to compute virtual cost calculation later, when you'll be spwaning **Kompute** instances with vCPUs and vGB of RAM. Each server being different, it's fully okay to have different values here for your fleet.
- **cpu_overcommit** and **memory_overcommit** define the [overcommit](https://en.wikipedia.org/wiki/Memory_overcommitment) ratio you accept your physical hosts to address. As for price, not every server is born equal. Some have hyper-threading, other don't. You may consider that a value of 3 or 4 is fine, other tend to be stricter and use 2 instead. The more you set the bar, the more virtual resources you'll be able to create but the less actual physical resources they'll be able to get.
{{< /alert >}}


```hcl
locals {
  currency           = "EUR"
  cpu_overcommit     = 3
  memory_overcommit  = 2

  eu-west = {
    zones = {
      "eu-west-a" = {
        id = "A"

        agents = {
          "kaktus-eu-west-a-1" = {
            desc = "Kaktus EU-WEST A-1 Agent"
            type = "Kaktus"
          }
          "kaktus-eu-west-a-2" = {
            desc = "Kaktus EU-WEST A-2 Agent"
            type = "Kaktus"
          }
          "kaktus-eu-west-a-3" = {
            desc = "Kaktus EU-WEST A-3 Agent"
            type = "Kaktus"
          }
        }

        kaktuses = {
          "kaktus-eu-west-a-1" = {
            desc        = "Kaktus EU-WEST A-1",
            cpu_cost    = 500
            memory_cost = 200
            agents      = ["kaktus-eu-west-a-1"]
          }
          "kaktus-eu-west-a-2" = {
            desc        = "Kaktus EU-WEST A-2",
            cpu_cost    = 500
            memory_cost = 200
            agents      = ["kaktus-eu-west-a-2"]
          }
          "kaktus-eu-west-a-3" = {
            desc        = "Kaktus A-3",
            cpu_cost    = 500
            memory_cost = 200
            agents      = ["kaktus-eu-west-a-3"]
          }
        }
      }
    }
  }
}

resource "kowabunga_agent" "eu-west-a" {
  for_each = merge(local.eu-west.zones.eu-west-a.agents)
  name     = each.key
  desc     = "${local.eu-west.desc} - ${each.value.desc}"
  type     = each.value.type
}

resource "kowabunga_kaktus" "eu-west-a" {
  for_each          = local.eu-west.zones.eu-west-a.kaktuses
  zone              = kowabunga_zone.eu-west["eu-west-a"].id
  name              = each.key
  desc              = "${local.eu-west.desc} - ${each.value.desc}"
  cpu_price         = each.value.cpu_cost
  memory_price      = each.value.memory_cost
  currency          = local.currency
  cpu_overcommit    = try(each.value.cpu_overcommit, local.cpu_overcommit)
  memory_overcommit = try(each.value.memory_overcommit, local.memory_overcommit)
  agents            = [for agent in try(each.value.agents, []) : kowabunga_agent.eu-west-a[agent].id]
}
```

And again, apply:

```sh
$ kobra tf apply
```

That done, **Kiwi** and **Kaktus** instances have been registered, but more essentially, their associated agents. For each newly created agent, you should have received an email (check the admin one you previously set in **Kahuna**'s configuration). Keep track of these emails, they contain one-time credentials about the agent identifier and it's associated API key.

This is the super secret thing that will allow them further to establish secure connection to **Kahuna** orchestrator. We're soon going to declare these credentials in Ansible's secrets so **Kiwi** and **Kaktus** instances can be provisioned accordingly.

{{< alert color="warning" title="Warning" >}}
There's no way to recover the agent API key. It's never printed anywhere but on the email you just received. Even the database doesn't contain it. If one agent's API key is lost, you can either request a new one from API or destroy the agent and create a new one in-place.
{{< /alert >}}

## Virtual Networks

Let's keep on provisioning **Kahuna**'s database with the network configuration from our [network topology](/docs/getting-started/topology/).

We'll use different VLANs (expressed as VNET or **V**irtual **NET**work in Kowabunga's terminology) to segregate tenant traffic:

- VLAN 0 (i.e. no VLAN) will be used for public subnets (i.e. where to hook public IP addresses).
- VLAN 102 will be dedicated to storage backend.
- VLANs 201 to 209 will be reserved for tenants/projects (automatically assigned at new project's creation).

{{< alert color="success" title="Note" >}}
Note that exposing Ceph storage network might come in handy if you intend to run applications which are expected to consume or provision resources directly on the underlying storage.

By default, if you only intend to use plain old **Kompute** instances, virtual disks are directly mapped by virtualization and you don't have to care about how. In that case, there's no specific need to expose VLAN 102.

If you however expect to further use **KFS** or running your own Kubernetes flavor, with an attempt to directly use Ceph backend to instantiate PVCs, exposing the VLAN 102 is mandatory.

To be on the safe side, and furure-proof, keep it exposed.
{{< /alert >}}


So let's extend our **terraform/main.tf** with the following VNET resources declaration for the newly registered region.

```hcl
resource "kowabunga_vnet" "eu-west" {
  for_each  = local.eu-west.vnets
  region    = kowabunga_region.eu-west.id
  name      = each.key
  desc      = try(each.value.desc, "EU-WEST VLAN ${each.value.vlan} Network")
  vlan      = each.value.vlan
  interface = each.value.interface
  private   = each.value.vlan == "0" ? false : true
}
```

This will iterate over a list of VNET objects that we'll define in **terraform/locals.tf** file:

```hcl
locals {
  eu-west = {
    vnets = {
      // public network
      "eu-west-0" = {
        desc      = "EU-WEST Public Network",
        vlan      = "0",
        interface = "br0",
      },

      // storage network
      "eu-west-102" = {
        desc      = "EU-WEST Ceph Storage Network",
        vlan      = "102",
        interface = "br102",
      },

      // services networks
      "eu-west-201" = {
        vlan      = "201",
        interface = "br201",
      },
      [...]
      "eu-west-209" = {
        vlan      = "209",
        interface = "br209",
      },
    }
  }
}
```

And again, apply:

```sh
$ kobra tf apply
```

What have we done here ? Simply iterating over VNETs to associate those with VLAN IDs and the name of Linux bridge interfaces which will be created on each **Kaktus** instance from the zone (see [further](/docs/getting-started/create-kaktus/)).

{{< alert color="success" title="Note" >}}
Note that while services instances will have dedicated reserved networks, we'll (conventionnally) add the VLAN 0 here (which is not really a VLAN at all).

**Kaktus** instances will be created with a **br0** bridge interface, mapped on host private network controller interface(s), where public IP addresses will be bound. This will allow further create virtual machines to be able to bind public IPs through the bridged interface.
{{< /alert >}}

## Subnets

Now that virtual networks have been registered, it's time to associate each of them with service subnets. Again, let's edit our **terraform/main.tf** to declare resources objects, on which we'll iterate.

```hcl
resource "kowabunga_subnet" "eu-west" {
  for_each    = local.eu-west.subnets
  vnet        = kowabunga_vnet.eu-west[each.key].id
  name        = each.key
  desc        = try(each.value.desc, "")
  cidr        = each.value.cidr
  gateway     = each.value.gw
  dns         = try(each.value.dns, each.value.gw)
  reserved    = try(each.value.reserved, [])
  gw_pool     = try(each.value.gw_pool, [])
  routes      = kowabunga_vnet.eu-west[each.key].private ? local.extra_routes : []
  application = try(each.value.app, local.subnet_application)
  default     = try(each.value.default, false)
}
```

Subnet objects are associated with a given virtual network and usual network settings (such as CIDR, route/rgateway, DNS server) are associated.

Note the use of 2 interesting parameters:

- **reserved**, which is basically a list of IP addresses ranges, which are part of the provided CIDR, but not not to be assigned to further created virtual machines and services. This may come in handy if you have specific use of static IP addresses in your project and want to ensure they'll never get assigned to anyone programmatically.
- **gw_pool**, which is a range of IP addresses that are to be assigned to each project's **Kawaii** instances as virtual IPs. These are fixed IPs (so that router address never changes, even if you do destroy/recreate service instances countless times). You usually need one per zone, not more. But it's safe to extend the range for future-use (e.g. adding new zones in your region).

Now let's declare the various subnets in **terraform/locals.tf** file as well:

```hcl
locals {
  subnet_application = "user"

  eu-west = {
      "eu-west-0" = {
        desc = "EU-WEST Public Network",
        vnet = "0",
        cidr = "4.5.6.0/26",
        gw   = "4.5.6.62",
        dns  = "9.9.9.9"
        reserved = [
          "4.5.6.0-4.5.6.0",   # network address
          "4.5.6.62-4.5.6.63", # reserved (gateway, broadcast)
        ]
      },

      "eu-west-102" = {
        desc = "EU-WEST Ceph Storage Network",
        vnet = "102",
        cidr = "10.50.102.0/24",
        gw   = "10.50.102.1",
        dns  = "9.9.9.9"
        reserved = [
          "10.50.102.0-10.50.102.69", # currently used by Iris(es) and Kaktus(es) (room for more)
        ]
        app = "ceph"
      },

      # /24 subnets
      "eu-west-201" = {
        vnet = "201",
        cidr = "10.50.201.0/24",
        gw   = "10.50.201.1",
        reserved = [
          "10.50.201.1-10.50.201.5",
        ]
        gw_pool = [
          "10.50.201.252-10.50.201.254",
        ]
      },
      [...]
      "eu-west-209" = {
        vnet = "209",
        cidr = "10.50.209.0/24",
        gw   = "10.50.209.1",
        reserved = [
          "10.50.209.1-10.50.209.5",
        ]
        gw_pool = [
          "10.50.209.252-10.50.209.254",
        ]
      },
    }
  }
}
```

{{< alert color="success" title="Note" >}}
Note that we arbitrary took multiple decisions here:

- Reserve the first 69 IP addresses of the **10.50.102.0/24** subnet for our region growth. Each project's **Kawaii** instance (one per zone) will bind an IP from the range. That's plain enough room for the 10 projects we intend to host. But this saves us some space, shall we need to extend our infrastructure, by adding new **Kaktus** instances.
- Use of /24 subnets. This is really up to each network administrator. You could pick whichever range you need which wouldn't collapse with what's currently in place.
- Limit virtual network to one single subnet. We could have added as much as needed.
- Reserve the first 5 IPs of each subnet. Remember, our 2 **Kiwi** instances are already configured to bind **.2** and **.3** (and **.1** is the VIP). We'll save a few exra room for future use (one never knows ...).
- Reserve the subnet's last 3 IP addresses for **Kawaii** gateways virtual IPs. We only have one zone for now, so 1 would have been anough, but again, we never know what the future holds ...
{{< /alert >}}

{{< alert color="warning" title="Warning" >}}
It is now time to read carefully what you wrote, really do. We just wrote down a bloated list of network settings, subnets, CIDRs, IP addresses and mistake have probably happened. While nothing's written in stone (you can always apply TF config again), better find it now, that wasting hours trying to figure out later why your virtual machine doesn't get network access ;-)
{{< /alert >}}

Once carefully reviewed, again, apply:

```sh
$ kobra tf apply
```

Let's continue and [provision our region's **Kiwi** instances](/docs/getting-started/create-kiwi/) !
