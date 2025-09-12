---
title: Kowabunga Features
linkTitle: Features
menu:
  main:
    weight: 20
---

{{% blocks/cover title="Kowabunga Features" image_anchor="bottom" height="auto" %}}

Unlimited, unconditioned, all-in.
{.mt-5}

{{% /blocks/cover %}}

{{% blocks/section %}}
Core Components
{.h1 .text-left}

Kowabunga features several core infrastructure components, used to expose REST API or provide underlying computing, network and storage capabilities.

{.text-justify-center}
{{< cardpane >}}
  {{< card header="**Kahuna**" >}}
  <img src="kahuna.png" class="img-fluid">

  The **orchestration system**: remotely controls every resource and maintains ecosystem consistent. Gateway to the Kowabunga REST API.

  {{< /card >}}
  {{< card header="**Koala**" >}}
  <img src="wip.png" class="img-fluid">

  Kowabunga **WebUI**: allows for day-to-day supervision and operation of the various projects and services.

  {{< /card >}}
  {{< card header="**Kiwi**" >}}
  <img src="wip.png" class="img-fluid">

  Kowabunga **SD-WAN node**: provides various network services like routing, firewall, DHCP, DNS, VPN, IPSec peering (with active-passive failover).
  {{< /card >}}
  {{< card header="**Kaktus**" >}}
  <img src="kaktus.png" class="img-fluid">

  Kowabunga **HCI node**: virtual computing hypervisor with distributed storage services.
  {{< /card >}}
{{< /cardpane >}}

{{% /blocks/section %}}

{{% blocks/section color="" %}}
Services
{.h1 .text-left}

Kowabunga features multiple -as-a-service components, which can be seamlessly deployed on your infrastructure.

{{< cardpane >}}
  {{< card header="**Kawaii**" >}}
  <img src="wip.png" class="img-fluid">

  **Kawaii** provides Internet Gateway services. It connects your various project instances to and possibly from Internet, featuring inbound firewall and network VPC and IPSec peering capabilities.
  {{< /card >}}
  {{< card header="**Kompute**" >}}
  <img src="wip.png" class="img-fluid">

  **Kompute** is the basic building block of your eco-system, providing virtual computing and block storage disks. Granularity scales per CPU and per GB of memory and disk, allowing for fully custom appliances.
  {{< /card >}}
  {{< card header="**Konvey**" >}}
  <img src="konvey.png" class="img-fluid">

  **Konvey** provides standalone TCP/UDP network load-balancer capabilities. It allows for public service exposure while routing incoming requests to several backends.
  {{< /card >}}
  {{< card header="**Kylo**" >}}
  <img src="kylo.png" class="img-fluid">

  **Kylo** provides distributed network file-system capabilities. It is 100% NFSv4 compatible, infinitely scalable and highly resilient and distributed, thanks to underlying Ceph backend.
  {{< /card >}}
{{< /cardpane >}}

{{% /blocks/section %}}
