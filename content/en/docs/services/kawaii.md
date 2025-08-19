---
title: Kawaii
description: Kowabunga Internet Gateway
weight: 4
---

**Kawaii** is your project's private Internet Gateway, with complete ingress/egress control.

It is the network gateway to your private network. All **Kompute** (and other services) instances always use **Kawaii** as their default gateway, relaying all traffic.

**Kawaii** itself relies on the underlying region's **Kiwi** SD-WAN nodes to provide access to both public networks (i.e. Internet) and possibly other projects' private subnets (when requested).

**Kawaii** is always the first service to be created (more exactly, other instances cloud-init boot sequence will likely wait until they reach a proper network connectivity, as **Kawaii** provides). Being critical for your project's resilience, **Kawaii** uses Kowabunga's concept of **Multi-Zone Resources** (MZR) to ensure that, when the requested regions feature multiple availability zones, a project's **Kawaii** instance gets created in each zone.

Using multiple floating virtual IP (VIP) addresses with per-zone affinity, this guarantees that all instantiates services will always be able to reach their associated network router. As much as can be, using weighted routes, service instances will target their zone-local **Kawaii** instance, the best pick for latency. In the unfortunate event of local zone's failure, network traffic will then automatically get routed to other zone's **Kawaii** (with an affordable extra millisecond penalty).

While obviously providing egress capability to all project's instance, **Kawaii** can also be used as an egress controller, exposed to public Internet through dedicated IPv4 address. Associated with a **Konvey** or **Kalipso** load-balancer, it make it simple to expose your application publicly, as one would do with a Cloud provider.

Kowabunga's API allows for complete control of the ingress/egress capability with built-in firewalling stack (deny-all filtering policy, with explicit port opening) as well as peering capabilities.

This allows you to inter-connect your project's private network with:

- VPC peering with other Kowabunga-hosted projects from the same region (network translation and routing being performed by underlying **Kiwi** instances).
- IPSEC peering with non-Kowabunga managed projects and network, from any provider.

{{< alert color="warning" title="Warning" >}}
Keep in mind that peering requires a bi-directional agreement. Connection and possibly firewalling must be configured at both endpoints.
{{< /alert >}}

Note that thanks to Kowabunga's internal network architecture and on-premises network backbone, inter-zones traffic is a free-of-charge possibility ;-) There's no reason not to spread your resources on as many zones as can be, you won't ever see any end-of-the-month surprise charge.
