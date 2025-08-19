---
title: Kaktus
description: Learn about Kaktus HCI node.
weight: 6
---

**Kaktus** stands for **K**owabunga **A**ffordable **K**vm and **TU**rnkey **S**torage (!!), basically, our Hyper-Converged Infrastructure (HCI) node.

While large virtualization systems such as VMware usually requires you to dedicate servers as computing hypervisors (with plenty of CPU and memory) and associate them with remote, extensive NAS or vSAN, providing storage, Kowabunga follows the opposite approach. Modern hardware is powerful enough to handle both computing and storage.

This approach allows you to:

- use commodity hardware, if needed
- use heterogenous hardware, each member of the pool featuring more or less computing and storage resources.

If you're already ordering a heavy computing rackable server, extending it with 4-8 SSDs is always going to be cheaper than adding an extra enterprise SAN.

**Kaktus** nodes will then consists of

- a [KVM](https://linux-kvm.org/page/Main_Page)/[QEMU](https://www.qemu.org/) + [libvirt](https://libvirt.org/) virtualization computing stack. Featuring all possible VT-x and VT-d assistance on x86_64 architectures, it'll provide near passthrough virtualization capabilities.
- several local disks, to be part of a region-global [Ceph](https://ceph.io/en/) distributed storage cluster.
- the **Kowabunga Kaktus agent**, connected to **Kahuna**

**Kaktus agent** controls the local **KVM** hypervisor through **libvirt** backend and the local-network distributed **Ceph** storage, allowing management of virtual machines and disks.

{{< alert color="success" title="Note" >}}
When configured for production-systems, Ceph storage cluster will be backed by cross-zones N-times (usually 3) replicated high-performance block devices, providing virtually infinitely scalable and resizeable disk volumes with byte-precision.

Virtual disks contents being sharded into thousands of fragmented objects, spread across the various disks from the various **Kaktus** instances of a given region, the "chance" of data loss or corruption is close to none.
{{< /alert >}}

{{< alert color="warning" title="Enterprise Recommendations" >}}
If you intend to use Kowabunga to run serious business (and we hope you'll do), you need to ensure to give Ceph its full potential.

Too many Cloud systems are today limited (CPU stuck in I/O wait) by disk bandwidth. Using Ceph, implies that your disks I/Os are to be adressed through network. Simply put, don't expect to get NVME SSDs access time.

In order to ensure the fastest storage possible, it remains key that you:

- use local NVMe SSDs on as much server instances as possible (they'll all be part of the same cluster pool).
- use physical servers with at 10 Gbps network interfaces (25 Gbps is even better, link-agregation is a nice bonus).
- ensure that your regional zones are less than 1ms away from each other.

This may sounds like heavy requirements, but by today enterprise-grade standards, it's really isn't anymore ;-)
{{< /alert >}}
