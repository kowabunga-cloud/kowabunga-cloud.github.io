---
title: Kawaii Internet Gateway
description: Kowabunga Internet Gateway
weight: 4
---

**Kawaii** is your project's private Internet Gateway, with complete ingress/egress control. It stands for **K**owabunga **A**daptive **WA**n **I**ntelligent **I**nterface (if you have better ideas, we're all ears ;-) ).

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

## Resource Creation

As a **projectAdmin** user, one can create a **Kawaii** Internet gateway for the **acme** project in **eu-west** region the following way:

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
data "kowabunga_region" "eu-west" {
  name = "eu-west"
}

resource "kowabunga_kawaii" "gw" {
  project = kowabunga_project.acme.id
  region  = data.kowabunga_region.eu-west.id
}
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

You may refer to [TF](https://search.opentofu.org/provider/kowabunga-cloud/kowabunga/latest/docs/resources/kawaii) documentation to extend **Kawaii** gateway with VPC peering and custom egress/ingress/nat rules.

## VPC Peering

Kowabunga VPC peering allows you to inter-connect 2 projects subnets. This can come in handy if you have 2 specific applications, managed by different set of people, and still need both to communicate all together.

The following example extends our **Kawaii** gateway configuration to peer with 2 subnets:

- the underlying Ceph one, used to directly access storage resources.
- the one form **marvelous** project, allowing bi-directional connectivity through associated ingress/egress firewalling rules.

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
resource "kowabunga_kawaii" "gw" {
  project = kowabunga_project.acme.id
  region  = data.kowabunga_region.eu-west.id
  vpc_peerings = [
    {
      subnet = data.kowabunga_subnet.eu-west-ceph.id
    },
    {
      subnet = data.kowabunga_subnet.eu-west-marvelous.id
      egress = {
        ports    = "1-65535"
        protocol = "tcp"
      }
      ingress = {
        ports    = "1-65535"
        protocol = "tcp"
      }
      policy = "accept"
    },
  ]
}
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

{{< alert color="warning" title="Warning" >}}
Note that setting up VPC peering requires you to configure and allow connectivity on both projects ends. Network is bi-directional and, for security measures, one project cannot arbitrary decide to peer with another one without mutual consent.
{{< /alert >}}

## IPsec Peering

Alternatively, it is also possible to setup an [IPsec peering connection](https://search.opentofu.org/provider/kowabunga-cloud/kowabunga/latest/docs/resources/kawaii_ipsec) with **Kawaii**, should you need to provide some admin users with remote access capabilities.

This allows connecting your private subnet with other premises or Cloud providers as to extend the reach of services behind the walls of Kowabunga.

The above example extend our **Kawaii** instance with an IPsec connection with the ACME remote office. The remote IPsec engine public IP address will be **5.6.7.8** and expose the private network **172.16.1.0/24**.

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
resource "kowabunga_kawaii_ipsec" "office" {
  kawaii                      = kowabunga_kawaii.gw.id
  name                        = "ACME Office"
  desc                        = "connect ro aws ipsec"
  pre_shared_key              = local.secrets.kowabunga.ipsec_office_psk
  remote_peer                 = "5.6.7.8"
  remote_subnet               = "172.16.1.0/24"
  phase1_dh_group_number      = 14
  phase1_integrity_algorithm  = "SHA512"
  phase1_encryption_algorithm = "AES256"
  phase2_dh_group_number      = 14
  phase2_integrity_algorithm  = "SHA512"
  phase2_encryption_algorithm = "AES256"
}
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

{{< alert color="warning" title="Warning" >}}
It comes without saying but setting up an IPsec tunnel requires you to:

- Expose both ends publicly
- Configure tunnel connectivity both ways.
- Configure both ends firewall, if necessary.
{{< /alert >}}
