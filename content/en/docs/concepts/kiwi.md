---
title: Kiwi
description: Learn about Kiwi SD-WAN node.
weight: 5
---

**Kiwi** is Kowabunga SD-WAN node in your local data-center. It provides various network services like routing, firewall, DHCP, DNS, VPN and peering, all with active-passive failover (ideally over multiple zones).

**Kiwi** is central to our regional infrastructure to operate smoothly and internal gateway to all your projects **Kawaii** private network instances. It controls the local network configuration and creates/updates VLANs, subnets and DNS entries per API requests.

**Kiwi** offers a Kowabunga project's network isolation feature by enabling VLAN-bound, cross-zones, project-attributed, VPC L3 networking range. Created virtual instances and services are bound to VPC by default and never publicly exposed unless requested.

Access to project's VPC resources is managed either through:

- **Kiwi-managed** region-global VPN tunnels.
- **Kawaii-managed** project-local VPN tunnels.

Decision to do or another depends on private Kowabunga IT policy.
