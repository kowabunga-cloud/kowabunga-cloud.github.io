---
title: Provisioning Kiwi
description: Let's provision our Kiwi instances
weight: 7
---

As detailed in [network topology](/docs/getting-started/topology/), we'll have 2 **Kiwi** instances:

- **kiwi-eu-west-1**:
  - with VLAN 101 as administrative segment with 10.50.101.2,
  - with VLAN 102 as storage segment with 10.50.102.2,
  - with VLAN 201 to 209 as service VLANs.
- **kiwi-eu-west-1**:
  - with VLAN 101 as administrative segment with 10.50.101.3,
  - with VLAN 102 as storage segment with 10.50.102.3,
  - with VLAN 201 to 209 as service VLANs.

Note that *10.50.101.1* and *10.50.102.1* will be used as virtual IPs (VIPs).

## Inventory Management

It is now time to declare your **Kiwi** instances in Ansible's inventory. Simply extend the **ansible/inventories/hosts.txt** the following way:

```ini
[kiwi]
10.50.101.2 name=kiwi-eu-west-1 ansible_ssh_user=ubuntu
10.50.101.3 name=kiwi-eu-west-2 ansible_ssh_user=ubuntu
```

{{< alert color="warning" title="Important" >}}
Note that for the first-time installation, private IPs from the inventory are to replaced by the servers private ones (or anything in place which allows for bootstrapping machines).
{{< /alert >}}

The instances are now declared to be part of **kiwi** group and Ansible will use **ubuntu** local user account to connect through SSH.

Note that doing so, you can now safely:

- declare host-specific variables in **ansible/host_vars/10.50.101.{2,3}.yml** files.
- declare host-specific sensitive variables in **ansible/host_vars/10.50.101.{2,3}.sops.yml** file.
- declare **kiwi** group-specific variables in **ansible/group_vars/kiwi/main.yml** file.
- declare **kiwi** group-specific sensitive variables in **ansible/group_vars/kiwi.sops.yml** file.
- declare any other global variables in **ansible/group_vars/all/main.yml** file.
- declare any other global sensitive variables in **ansible/group_vars/all.sops.yml** file.

Note that Ansible variables precedence will apply:

```txt
role defaults < all vars < group vars < host vars < role vars
```

## Network Configuration

We'll instruct the Ansible collection to provision network settings through [Netplan](https://netplan.io/). Note that our example is pretty simple, with only a single network interface to be used for private LAN, no link aggregation being used (recommended for enterprise-grade setups).

Let's declare the following configuration in **ansible/inventories/host_vars/10.50.101.2.yml** file:

```yaml
kowabunga_netplan_config:
  ethernet:
    - name: "{{ wan_dev }}"
      mac: "aa:bb:cc:dd:ee:ff"
      ips:
        - a.b.c.d/24
      routes:
        - to: default
          via: e.c.d.f
    - name: "{{ lan_dev }}"
      mac: "aa:bb:cc:dd:ee:ff"
  vlan:
    # EU-WEST admin network
    - name: vlan101
      id: 101
      link: "{{ lan_dev }}"
      ips:
        - 10.50.101.2/24
    # EU-WEST storage network
    - name: vlan102
      id: 102
      link: "{{ lan_dev }}"
      ips:
        - 10.50.102.2/24
    # EU-WEST services networks
    - name: vlan201
      id: 201
      link: "{{ lan_dev }}"
      ips:
        - 10.50.201.2/24
    [...]
    - name: vlan209
      id: 209
      link: "{{ lan_dev }}"
      ips:
        - 10.50.209.2/24
```

You'll need to ensure that the MAC addresses and host and gateway IP addresses are correctly set, depending on your setup. Once done, you can do the same for the alternate **Kiwi** instance in **ansible/inventories/host_vars/10.50.101.2.yml** file file.

Extend the **ansible/inventories/group_vars/kiwi/main.yml** file with the following to ensure generic settings are propagated to all **Kiwi** instances:

```yaml
kowabunga_netplan_disable_cloud_init: true
kowabunga_netplan_apply_enabled: true
```

{{< alert color="success" title="Information" >}}
Note that setting **kowabunga_netplan_disable_cloud_init** is an optional step. If you'd like to keep whatever configuration cloud-init has previously set, it's all fine (but it's always recommended not to have dual sourc eof truth).
{{< /alert >}}

## Network Failover

Each **Kiwi** instance configuration is now set to receive host-specific network configuration. But they are meant to work in an HA-cluster, so let's define some redundancy rules. The two instances respectively bind the **.2** and **.3** private IPs from each subnet, but our active router will be **.1**, so let's define network failover configuration for that.

Again, extend the **ansible/inventories/group_vars/kiwi/main.yml** file with the following configuration:

```yaml
kowabunga_kiwi_primary_host: "kiwi-eu-west-1"
kowabunga_network_failover_settings:
  peers: "{{ groups['kiwi'] }}"
  use_unicast: true
  trackers:
    - name: kiwi-eu-west-vip
      configs:
        - vip: 10.50.101.1/24
          vrid: 101
          primary: "{{ kowabunga_kiwi_primary_host }}"
          control_interface: vlan101
          interface: vlan101
          nopreempt: true
        - vip: 10.50.102.1/24
          vrid: 102
          primary: "{{ kowabunga_kiwi_primary_host }}"
          control_interface: vlan102
          interface: vlan102
          nopreempt: true
        - vip: 10.50.201.1/24
          vrid: 201
          primary: "{{ kowabunga_kiwi_primary_host }}"
          control_interface: vlan201
          interface: vlan201
          nopreempt: true
        [...]
        - vip: 10.50.209.1/24
          vrid: 209
          primary: "{{ kowabunga_kiwi_primary_host }}"
          control_interface: vlan209
          interface: vlan209
          nopreempt: true
```

This will ensure that VRRP packets flows between the 2 peers so one always ends up being the active router for each virtual network interface.
