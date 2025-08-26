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

Let's continue and [provision our region's **Kiwi** instances](/docs/getting-started/create-kiwi/) !
