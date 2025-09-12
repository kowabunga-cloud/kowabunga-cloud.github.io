---
title: Provisioning Kaktus
description: Let's provision our **Kaktus** instances
weight: 6
---

As detailed in [network topology](/docs/getting-started/topology/), we'll have 3 **Kaktus** instances:

- **kaktus-eu-west-a-1**:
  - with VLAN 101 as administrative segment with 10.50.101.11,
  - with VLAN 102 as storage segment with 10.50.102.11,
  - with VLAN 201 to 209 as service VLANs.
- **kaktus-eu-west-a-2**:
  - with VLAN 101 as administrative segment with 10.50.101.12,
  - with VLAN 102 as storage segment with 10.50.102.12,
  - with VLAN 201 to 209 as service VLANs.
- **kaktus-eu-west-a-3**:
  - with VLAN 101 as administrative segment with 10.50.101.13,
  - with VLAN 102 as storage segment with 10.50.102.13,
  - with VLAN 201 to 209 as service VLANs.

## Pre-Requisites

Kaktus nodes will serve both as computing and storage backends. While computing is easy (one just need to ease available CPU and memory), storage is different as we need to prepare hard disks (well ... SSDs) and set them up to be part of a coherent Ceph cluster.

As a pre-requisite, you'll then need to ensure that your server has freely available disks for that purpose.

If you only have limited disks on your system (e.g. only 2), Ceph storage will be physically collocated with your OS. Best scenario would then be to:

- partition your disks to have a small reserved partition (e.g. 32 to 64 GB) to your OS
- possibly do the same on another disk so you can use software RAID-1 for sanity.
- partition the rest of your disk for future Ceph usage.

In that case, **parted** is your friend for the job. It also means you need to ensure, at OS installation stage, that you don't let distro partitioner use your full device.

{{< alert color="success" title="Recommendation" >}}
As much as can be, we however recommend you to have dedicated disks for Ceph cluster. An enterprise-grade setup would use some small SATA SSDs in RAID-1 for OS and as many dedicated NVMe SSDs as Ceph-reserved data disks.
{{< /alert >}}

## Inventory Management

If required, update your **Kaktus** instances in Ansible's inventory.

{{< alert color="warning" title="Important" >}}
Note that for the first-time installation, private IPs from the inventory are to replaced by the servers private ones (or anything in place which allows for bootstrapping machines).
{{< /alert >}}

The instances are now declared to be part of **kaktus**, **kaktus_eu_west** and **eu_west** groups.

## Network Configuration

We'll instruct the Ansible collection to provision network settings through [Netplan](https://netplan.io/). Note that our example is pretty simple, with only a single network interface to be used for private LAN, no link aggregation being used (recommended for enterprise-grade setups).

As the configuration is both instance-specific (private MAC address, IP address ...), region-specific (all **Kaktus** instance will do likely the same), and, as such, repetitive, we'll use some Ansible overlaying.

We've already declare quite a few stuff at region level when creating **eu-west** one.

Let's now extend the **ansible/inventories/group_vars/kaktus_eu_west/main.yml** file with the following:

```yaml
kowabunga_netplan_vlan_config_default:
    # EU-WEST admin network
    - name: vlan101
      id: 101
      link: "{{ kowabunga_host_vlan_underlying_interface }}"
      ips:
        - "{{ kowabunga_region_domain_admin_host_address }}/{{ kowabunga_region_domain_admin_network | ansible.utils.ipaddr('prefix') }}"
      routes:
        - to: default
          via: "{{ kowabunga_region_domain_admin_router_address }}"
    # EU-WEST storage network
    - name: vlan102
      id: 102
      link: "{{ kowabunga_host_vlan_underlying_interface }}"

kowabunga_netplan_bridge_config_default:
  - name: br0
    interfaces:
      - "{{ kowabunga_host_underlying_interface }}"
  - name: br102
    interfaces:
      - vlan102
    ips:
      - "{{ kowabunga_region_domain_storage_host_address }}/{{ kowabunga_region_domain_storage_network | ansible.utils.ipaddr('prefix') }}"
    routes:
      - to: default
        via: "{{ kowabunga_region_domain_storage_router_address }}"
        metric: 200

# Region-generic configuration template, variables set at host level
kowabunga_netplan_config:
  ethernet:
    - name: "{{ kowabunga_host_underlying_interface }}"
      mac: "{{ kowabunga_host_underlying_interface_mac }}"
  vlan: |
    {%- set res = kowabunga_netplan_vlan_config_default -%}
    {%- for r in kowabunga_region_vlan_id_ranges[1:] -%}
    {%- for id in range(r.from, r.to + 1, 1) -%}
    {%- set dummy = res.extend([{"name": "vlan" + id | string, "id": id, "link": kowabunga_host_vlan_underlying_interface}]) -%}
    {%- endfor -%}
    {%- endfor -%}
    {{- res -}}
  bridge: |
    {%- set res = kowabunga_netplan_bridge_config_default -%}
    {%- for r in kowabunga_region_vlan_id_ranges[1:] -%}
    {%- for id in range(r.from, r.to + 1, 1) -%}
    {%- set dummy = res.extend([{"name": "br" + id | string, "interfaces": ["vlan" + id | string]}]) -%}
    {%- endfor -%}
    {%- endfor -%}
    {{- res -}}
```

As for **Kiwi** previously, this looks like a dirty Jinja hack but it actually comes handy, saving you from copy/paste mistakes and iterating over all VLANs and bridges. We'll still need to add instance-specific variables, by extending the **ansible/inventories/host_vars/kaktus-eu-west-a-1** file:

```yaml
kowabunga_host_underlying_interface: eth0
kowabunga_host_underlying_interface_mac: "aa:bb:cc:dd:ee:ff"
kowabunga_host_vlan_underlying_interface: eth0

kowabunga_region_domain_admin_host_address: 10.50.101.11
kowabunga_region_domain_storage_host_address: 10.50.102.11
```

You'll need to ensure that the physical interface, MAC address and host admin+storage network addresses are correctly set, depending on your setup. Once done, you can do the same for the alternate **Kaktus** instances in **ansible/inventories/host_vars/kaktus-eu-west-a-{2,3}.yml** files.

Extend the **ansible/inventories/group_vars/kaktus/main.yml** file with the following to ensure generic settings are propagated to all **Kaktus** instances:

```yaml
kowabunga_netplan_disable_cloud_init: true
kowabunga_netplan_apply_enabled: true
```

{{< alert color="success" title="Information" >}}
Note that setting **kowabunga_netplan_disable_cloud_init** is an optional step. If you'd like to keep whatever configuration cloud-init has previously set, it's all fine (but it's always recommended not to have dual source of truth).
{{< /alert >}}

{{< alert color="success" title="Information" >}}
Note that, by opposition to **Kiwi** instances, services VLAN (201 to 209) interfaces will be left unconfigured (i.e. no IP address). None is actually needed, as we're creating bridge interfaces on top, which are meant for further **Kompute** virtual instances to be able to bind the appropriate underlying VLAN interface.
{{< /alert >}}

## Storage Setup

It is now time to setup the Ceph cluster ! As complex as it may sounds (and it is), Ansible will populate everything for you.

So let's start by defining a new cluster identifier and associated region, through **ansible/inventories/group_vars/kaktus_eu_west/main.yml** file:

```yaml
kowabunga_ceph_fsid: "YOUR_CEPH_REGION_FSID"
kowabunga_ceph_group: kaktus_eu_west
```

The FSID is a simple UUID. It's only constraint is to be unique amongst your whole network (should you have multiple Ceph clusters). Keep track of it, we'll need to push this information to Kowabunga DB later on.

### Monitors and Managers

Ceph cluster comes with several nodes as **monitors**. Simply put they are exposing the Ceph cluster API. You don't need all nodes to be monitors. One is enough, while 3 is recommended, for high-availability and distributing workload. Each **Kaktus** instance can be turned into a Ceph monitor node.

One simply need to declare so in **ansible/inventories/host_vars/kaktus-eu-west-a-{1,2,3}.yml** instance-specific file:

```yaml
kowabunga_ceph_monitor_enabled: true
kowabunga_ceph_monitor_listen_addr: "{{ kowabunga_region_domain_storage_host_address }}"
```

{{< alert color="success" title="Information" >}}
Having more than 3 monitors in your cluster is not necessarily useful. If you have more than 3 instances in your region and need to choose, simply pick the most powerful servers (hardware characteristics wise) and they'll process the heavy lifting.

Also be sure that those nodes (and those nodes only !) are defined in **Kiwi**'s DNS regional configuration under **ceph** record.
{{< /alert >}}

Ceph cluster also comes with **managers**. As in real-life, they don't do much ;-) Or at least, they're not as vital as **monitors**. They however expose various metrics. Having one is nice, more than that will only help with failover. As for **monitors**, one can enable it for a **Kaktus** in **ansible/inventories/host_vars/kaktus-eu-west-a-{1,2,3}.yml** instance-specific file:

```yaml
kowabunga_ceph_manager_enabled: true
```

and its related administration password in **ansible/inventories/group_vars/kaktus.sops.yml** file:

```yaml
secret_kowabunga_ceph_manager_admin_password: PASSWORD
```

This will help you connect to Ceph cluster WebUI, which is always handy when troubleshooting is required.

### Authentication keyrings

Once running, Ansible will also generate specific keyrings at cluster's boostrap. Once generated, these keyrings will be locally stored (and for you to be added to source control) and deployed to further nodes.

So let's define where to store these files in **ansible/inventories/group_vars/kaktus/main.yml** file:

```yaml
kowabunga_ceph_local_keyrings_dir: "{{ playbook_dir }}/../../../../../files/ceph"
```

Once provisioned, you'll end up with a regional sub-directory (e.g. **eu-west**), containing 3 files:

- ceph.client.admin.keyring
- ceph.keyring
- ceph.mon.keyring

{{< alert color="warning" title="Important" >}}
These files are keyring and extremely sensitive. Anyone with access to these files and your private network gets a full administrative control over the Ceph cluster.

So keep track of them, but do it smartly. As they are plain-text, let's ensure you don't store them on Git that way.

A good move is to have them SOPS encrypted:

```sh
$ kobra secrets encrypt ceph.client.admin.keyring
$ mv ceph.client.admin.keyring ceph.client.admin.keyring.sops
```

before being pushed. Ansible will automatically decrypt them on the fly, should they end up with *.sops* extension.
{{< /alert >}}

### Disks provisioning

Next step is about disks provisioning. Your cluster will contain several disks from several instances (the ones you've either partitioned or left untouched at pre-requisite stage). Each instance may have different topology, different disks, different sizes etc ... Disks (or partitions, whatever) are each managed by a Ceph **OSD** daemon.

So we need to reflect this topology into each instance-specific **ansible/inventories/host_vars/kaktus-eu-west-a-{1,2,3}.yml** file:

```yaml
kowabunga_ceph_osds:
  - id: 0
    dev: /dev/disk/by-id/nvme-XYZ-1
    weight: 1.0
  - id: 1
    dev: /dev/disk/by-id/nvme-XYZ-2
    weight: 1.0
```

For each instance, you'll need to declare disks that are going to be part of the cluster. The **dev** parameter simply maps to the device file itself (it is **more than recommended** to use **/dev/disk/by-id** mapping instead of bogus **/dev/nvme0nX** naming, which can change across reboots). The **weight** parameter will be used for Ceph scheduler for object placement and corresponds to each disk size in TB unit (e.g. 1.92 TB SSD would have a 1.92 weight). And finally the **id** identifier might be the most important of all. This is the **UNIQUE** identifier across your Ceph cluster. Whichever the disk ID you use, you need to ensure than no other disk in no other instance uses the same identifier.

### Data Pools

Once we have disks aggregated, we must create data pools on top. Data pools are a logical way to segment your global Ceph cluster usage. Definition can be made in **ansible/inventories/group_vars/kaktus_eu_west/main.yml** file, as:

```yaml
kowabunga_ceph_osd_pools:
  - name: rbd
    ptype: rbd
    pgs: 256
    replication:
      min: 1
      request: 2
  - name: nfs_metadata
    ptype: fs
    pgs: 128
    replication:
      min: 2
      request: 3
  - name: nfs_data
    ptype: fs
    pgs: 64
    replication:
      min: 1
      request: 2
  - name: kubernetes
    ptype: rbd
    pgs: 64
    replication:
      min: 1
      request: 2
```

In that example, we'll create 4 data pools:

- 2 of type **rbd** (RADOS block device), for further be used by KVM or a future Kubernetes cluster to provision virtual block device disks.
- 2 of type **fs** (filesystem), for further be used as underlying NFS storage backend.

Each pool relies on [Ceph Placement Groups](https://docs.ceph.com/en/latest/rados/operations/placement-groups/) for objects fragments distribution across disks in the cluster. There's no rule of thumb on how much one need. It depends on your cluster size, its number of disks, its replication factor and many more parameters. You can get some help thanks to [Ceph PG Calculator](https://linuxkidd.com/ceph/pgcalc.html) to set an appropriate value.

The **replication** parameter controls the cluster's data redundancy. The bigger the value, the more replicated data will be (and the less prone to disaster you will be), but the fewer usable space you'll get.

### File Systems

Shall you be willing to share your Ceph cluster as a distributed filesystem (e.g. with **Kylo** service), you'll need to enable **CephFS** support.

Once again, this can be enabled through instance-specific definition in **ansible/inventories/host_vars/kaktus-eu-west-a-{1,2,3}.yml** file:

```yaml
kowabunga_ceph_fs_enabled: true
```

and more globally in **ansible/inventories/group_vars/kaktus/main.yml**

```yaml
kowabunga_ceph_fs_filesystems:
  - name: nfs
    metadata_pool: nfs_metadata
    data_pool: nfs_data
    default: true
    fstype: nfs
```

where we'd instruct Ceph to use our two previously created pools for underlying storage.

### Storage Clients

Finally, we must declare clients, allowed to connect to our Ceph cluster. We don't really expect remote users to connect to, only **libvirt** instances (and possibly **kubernetes** instances, shall we deploy such), so declaring these in **ansible/inventories/group_vars/kaktus/main.yml** file should be enough:

```yaml
kowabunga_ceph_clients:
  - name: libvirt
    caps:
      mon: "profile rbd"
      osd: "profile rbd pool=rbd"
  - name: kubernetes
    caps:
      mon: "profile rbd"
      osd: "profile rbd pool=kubernetes"
      mgr: "profile rbd pool=kubernetes"
```

## Kaktus Agent

Finally, let's take care of **Kaktus** agent. The agent will establish its secured WebSocket connection to **Kahuna**, receives configuration changes from, and apply accordingly.

Now remember that we previously used TF to [register new Kaktus agents](/docs/admin-guide/create-region/#kaktus-instances-and-agents). Once applied, emails were sent for each instance with a set of agent identifier and API key. These values now have to be provided to Ansible, as these are going to be the credentials used by **Kaktus** agent to connect to **Kahuna**.

So let's edit each Kaktus instance secrets file in respectively **ansible/inventories/host_vars/kaktus-eu-west-a-{1,2}.sops.yml** files:

```yaml
secret_kowabunga_kaktus_agent_id: AGENT_ID_FROM_KAHUNA_EMAIL_FROM_TF_PROVISIONING_STEP
secret_kowabunga_kaktus_agent_api_key: AGENT_API_KEY_FROM_KAHUNA_EMAIL_FROM_TF_PROVISIONING_STEP
```

## Ansible Deployment

We're finally done with **Kaktus**'s configuration. All we need to do now is finally run Ansible to make things live. This is done by invoking the **kaktus** playbook from the **kowabunga.cloud** collection:

```sh
$ kobra ansible deploy -p kowabunga.cloud.kaktus
```

We’re all set with infrastructure setup.

One last step of [services provisioning](/docs/admin-guide/provision-services/) and we're done !
