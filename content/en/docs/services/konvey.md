---
title: Konvey
description: Kowabunga Network Load-Balancer
weight: 7
---

**Konvey** is a plain simple network Layer-4 (UDP/TCP) load-balancer.

It's only goal is to accept remote traffic and ship it back to one of the many application backend, through round-robin algorithm (with health check support).

**Konvey** can either be used to:

- load-balance traffic from private network to private network
- load-balance traffic from public network (i.e. Internet) to private network, in association with **Kawaii**. In such a scenario, **Kawaii** holds public IP address exposure, and route public traffic to **Konvey** instances, through NAT settings.

As with **Kawaii**, **Konvey** uses Kowabunga's concept of **Multi-Zone Resources** (MZR) to ensure that, when the requested region features multiple availability zones, a project's **Konvey** instance gets created in each zone, making it highyl resilient.

{{< alert color="warning" title="Warning" >}}
Being a layer-4 network load-balancer, **Konvey** will passthrough any SSL/TLS traffic to configured backend. No traffic inspection is ever performed.
{{< /alert >}}
