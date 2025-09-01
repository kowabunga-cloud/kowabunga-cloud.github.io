---
title: Provisioning Kaktus
description: Let's provision our **Kaktus** instances
weight: 5
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

## Inventory Management

It is now time to declare your **Kaktus** instances in Ansible's inventory. Simply extend the **ansible/inventories/hosts.txt** the following way:

```ini
[kaktus]
10.50.101.11 name=kaktus-eu-west-a-1 ansible_ssh_user=ubuntu
10.50.101.12 name=kaktus-eu-west-a-2 ansible_ssh_user=ubuntu
10.50.101.13 name=kaktus-eu-west-a-3 ansible_ssh_user=ubuntu
```

{{< alert color="warning" title="Important" >}}
Note that for the first-time installation, private IPs from the inventory are to replaced by the servers private ones (or anything in place which allows for bootstrapping machines).
{{< /alert >}}

The instances are now declared to be part of **kaktus** group and Ansible will use **ubuntu** local user account to connect through SSH.

Note that doing so, you can now safely:

- declare host-specific variables in **ansible/host_vars/10.50.101.{11,12,13}.yml** files.
- declare host-specific sensitive variables in **ansible/host_vars/10.50.101.{11,12,13}.sops.yml** file.
- declare **kaktus** group-specific variables in **ansible/group_vars/kaktus/main.yml** file.
- declare **kaktus** group-specific sensitive variables in **ansible/group_vars/kaktus.sops.yml** file.
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
    - name: "{{ lan_dev }}"
      mac: "aa:bb:cc:dd:ee:ff"
  vlan:
    # EU-WEST admin network
    - name: vlan101
      id: 101
      link: "{{ lan_dev }}"
      ips:
        - 10.50.101.11/24
      routes:
        - to: default
          via: 10.50.101.1
    # EU-WEST storage network
    - name: vlan102
      id: 102
      link: "{{ lan_dev }}"
      ips:
        - 10.50.102.11/24
    # EU-WEST services networks
    - name: vlan201
      id: 201
      link: "{{ lan_dev }}"
    [...]
    - name: vlan209
      id: 209
      link: "{{ lan_dev }}"
```

You'll need to ensure that the MAC addresses and host and gateway IP addresses are correctly set, depending on your setup. Once done, you can do the same for the alternate **Kaktus** instances in **ansible/inventories/host_vars/10.50.101.{12,13}.yml** files.

Extend the **ansible/inventories/group_vars/kaktus/main.yml** file with the following to ensure generic settings are propagated to all **Kaktus** instances:

```yaml
kowabunga_netplan_disable_cloud_init: true
kowabunga_netplan_apply_enabled: true
```

{{< alert color="success" title="Information" >}}
Note that setting **kowabunga_netplan_disable_cloud_init** is an optional step. If you'd like to keep whatever configuration cloud-init has previously set, it's all fine (but it's always recommended not to have dual sourc eof truth).
{{< /alert >}}

{{< alert color="success" title="Information" >}}
Note that, by opposition to **Kiwi** instances, services VLAN (201 to 209) interfaces will be left unconfigured (i.e. no IP address). None is actually needed, as we're creating bridge interfaces on top, which are meant for further **Kompute** virtual instances to be able to bind the appropriate underlying VLAN interface.
{{< /alert >}}
