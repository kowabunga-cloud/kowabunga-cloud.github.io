---
title: Network Topology
description: Our Tutorial network topology
weight: 3
---

Let's use this sample network topology for the rest of this tutorial:

![Network Topology](/images/network-topology.png#center)

We'll start with a single **Kahuna** instance, with public Internet exposure. The instance's hostname will be **kowabunga-kahuna-1** and it has 2 network adapters and associated IP addresses:

- a private one, **10.0.0.1**, in the event we'd need to peer further one with other instances for hugh-availability.
- a public one, **1.2.3.4**, exposed as **kowabunga.acme.com** for WebUI, REST API calls to the orchestrator and WebSocket agents endpoint. It'll also be exposed as **grafana.acme.com**, **logs.acme.com** and **metrics.acme.com** for **Kiwi** and **Kaktus** to push logs and and metrics and allow for service's metrology.

Next is the main (and only) region, **EU-WEST** and its single zone, **EU-WEST-A**. The region/zone will feature 2 **Kiwi** instances and 3 **Kaktus** ones.

All instances will be connected under the same L2 network layer (as defined in requirements) and we'll use different VLANs and associated network subnets to isolate content:

- **VLAN 0** (i.e. no VLAN) will be used as public segment, with associated RIPE block **4.5.6.0/26**. All **Kaktus** instances will be able to bind these public IPs and translate those to **Kompute** virtual machine instances through bridged network adapters.
- **VLAN101** will be used as default, administration VLAN, with associated **10.50.101.0/24** subnet. All **Kiwi** and **Kaktus** instances will be part of.
- **VLAN102** will be used for Ceph backpanel, with associated **10.50.102.0/24** subnet. While not mandatory, this allows differentiating the administrative control plane traffic from pure storage cluster data synchronization. This allows for better traffic shaping and monitoring, if ever needs be. Note that on enterprise-grade production systems, Ceph project would recommend to use dedicated NIC for Ceph traffic, so isolation here makes sense.
- **VLAN201** to **VLAN209** would be application VLANs. **Kiwi** will bind them, being region's router, but **Kaktus** don't. Instantiated VMs will however, through bridged network adapters.

{{% alert color="warning" title="Warning" %}}
It is suggested to use manual fixed-address for **Kiwi** and **Kaktus** instances. Being critical, you wouldn't jeopardize the risk of service interruption because of a DHCP lease issue.
{{% /alert %}}

{{% alert color="success" title="Note" %}}
Note that while **Kiwi** instances have static IP addresses (namely **.2** and **.3**), they'll also use a **.1** as virtual IP (VIP), which is used for failover. Consequently, the **.1** will always be the network's router/gateway here, whichever **Kiwi** instace will hold it.
{{% /alert %}}

