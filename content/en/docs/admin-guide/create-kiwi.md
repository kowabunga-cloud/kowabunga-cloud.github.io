---
title: Provisioning Kiwi
description: Let's provision our **Kiwi** instances
weight: 5
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

If required, update your **Kiwi** instances in Ansible's inventory.

{{< alert color="warning" title="Important" >}}
Note that for the first-time installation, private IPs from the inventory are to replaced by the servers private ones (or anything in place which allows for bootstrapping machines).
{{< /alert >}}

The instances are now declared to be part of **kiwi**, **kiwi_eu_west** and **eu_west** groups.

## Network Configuration

We'll instruct the Ansible collection to provision network settings through [Netplan](https://netplan.io/). Note that our example is pretty simple, with only a single network interface to be used for private LAN, no link aggregation being used (recommended for enterprise-grade setups).

As the configuration is both instance-specific (private MAC address, IP address ...), region-specific (all **Kiwi** instance will do likely the same), and, as such, repetitive, we'll use some Ansible overlaying.

We've already declare quite a few stuff at region level when creating **eu-west** one.

Let's now extend the **ansible/inventories/group_vars/kiwi_eu_west/main.yml** file with the following:

```yaml
kowabunga_netplan_config:
  ethernet:
    - name: "{{ kowabunga_host_underlying_interface }}"
      mac: "{{ kowabunga_host_underlying_interface_mac }}"
      ips:
        - "4.5.6.{{ kowabunga_host_public_ip_addr_suffix }}/26"
      routes:
        - to: default
          via: 4.5.6.1
  vlan: |
    {%- set res=[] -%}
    {%- for r in kowabunga_region_vlan_id_ranges -%}
    {%- for id in range(r.from, r.to + 1, 1) -%}
    {%- set dummy = res.extend([{"name": "vlan" + id | string, "id": id, "link": kowabunga_host_vlan_underlying_interface, "ips": [r.net_prefix | string + "." + id | string + "." + kowabunga_host_vlan_ip_addr_suffix | string + "/" + r.net_mask | string]}]) -%}
    {%- endfor -%}
    {%- endfor -%}
    {{- res -}}
```

As ugly as it looks, this Jinja macro will help us iterate over all the VLAN interfaces we need to create by simply taking a few instance-specific variables into consideration.

And that's exactly what we'll define in **ansible/inventories/host_vars/kiwi-eu-west-1** file:

```yaml
kowabunga_primary_network_interface: eth0

kowabunga_host_underlying_interface: "{{ kowabunga_primary_network_interface }}"
kowabunga_host_underlying_interface_mac: "aa:bb:cc:dd:ee:ff"
kowabunga_host_vlan_underlying_interface: "{{ kowabunga_primary_network_interface }}"
kowabunga_host_public_ip_addr_suffix: 202
kowabunga_host_vlan_ip_addr_suffix: 2
```

You'll need to ensure that the MAC addresses and host and gateway IP addresses are correctly set, depending on your setup. Once done, you can do the same for the alternate **Kiwi** instance in **ansible/inventories/host_vars/kiwi-eu-west-2.yml** file.

Extend the **ansible/inventories/group_vars/kiwi/main.yml** file with the following to ensure generic settings are propagated to all **Kiwi** instances:

```yaml
kowabunga_netplan_disable_cloud_init: true
kowabunga_netplan_apply_enabled: true
```

{{< alert color="success" title="Information" >}}
Note that setting **kowabunga_netplan_disable_cloud_init** is an optional step. If you'd like to keep whatever configuration cloud-init has previously set, it's all fine (but it's always recommended not to have dual source of truth).
{{< /alert >}}

## Network Failover

Each **Kiwi** instance configuration is now set to receive host-specific network configuration. But they are meant to work in an HA-cluster, so let's define some redundancy rules. The two instances respectively bind the **.2** and **.3** private IPs from each subnet, but our active router will be **.1**, so let's define network failover configuration for that.

Again, extend the region-global **ansible/inventories/group_vars/kiwi_eu_west/main.yml** file with the following configuration:

```yaml
kowabunga_kiwi_primary_host: "kiwi-eu-west-1"

kowabunga_network_failover_settings:
  peers: "{{ groups['kiwi_eu_west'] }}"
  use_unicast: true
  trackers:
    - name: kiwi-eu-west-vip
      configs: |
        {%- set res = [] -%}
        {%- for r in kowabunga_region_vlan_id_ranges -%}
        {%- for id in range(r.from, r.to + 1, 1) -%}
        {%- set dummy = res.extend([{"vip": r.net_prefix | string + "." + id | string + ".1/" + r.net_mask | string, "vrid": id, "primary": kowabunga_kiwi_primary_host, "control_interface": kowabunga_primary_network_interface, "interface": "vlan" + id | string, "nopreempt": true}]) -%}
        {%- endfor -%}
        {%- endfor -%}
        {{- res -}}
```

Once again, we interate over **kowabunga_region_vlan_id_ranges** variable to create our global configuration for **eu-west** region. After all, both **Kiwi** instances from there will have the very same configuration.

This will ensure that VRRP packets flows between the 2 peers so one always ends up being the active router for each virtual network interface.

## Firewall Configuration

When running the Ansible playbook, **Kiwi** instances will be automatically configured as network routers. This is mandatory to ensure packets flow from WAN to LAN (and reciprocally) to inter-VLANs for services.

Configuring the associated firewall may then comes in handy.

There 2 possible options:

- **Kiwi** remains a private gateway, non-exposed to public Internet. This may be the case if you intend to only run Kowabunga as private corporate infrastructure only. Projects will get their own private network and the 'public' one will actually consist of one of your company's private subnet.
- **Kiwi** is a public gateway, exposed to public Internet.

In all cases, extend the **ansible/inventories/group_vars/kiwi/main.yml** file with the following to enable firewalling:

```yaml
kowabunga_firewall_enabled: true
```

In our first case scenario, simply configure the firewall as pass-through NAT gateway. Traffic from all interfaces will simply be forwarded:

```yaml
kowabunga_firewall_passthrough_enabled: true
```

In the event of a public gateway, things are a bit more complex, and you should likely refer to the [Ansible firewall module documentation](https://ansible.kowabunga.cloud/kowabunga/cloud/firewall_role.html#ansible-collections-kowabunga-cloud-firewall-role) to declare the following:

```yaml
kowabunga_firewall_dnat_rules: []
kowabunga_firewall_forward_interfaces: []
kowabunga_firewall_trusted_public_ips: []
kowabunga_firewall_lan_extra_nft_rules: []
kowabunga_firewall_wan_extra_nft_rules: []
```

with actual rules, depending on your network configuration and access means and policy (e.g. remote VPN access).

## PowerDNS Setup

{{< alert color="success" title="Information" >}}
Documentation below is ephemeral.

Kiwi currently relies on [PowerDNS](https://www.powerdns.com/) as a third-party DNS server. Current deployment comes bundled, associated with a [MariaDB](https://mariadb.org/) backend.

This is a temporary measure only. Next stable versions of **Kiwi** will soon feature a standalone DNS server implementation, nullifying all third-aprty dependencies and configuration requirements.
{{< /alert >}}

In order to deploy and configure **PowerDNS** and its associated **MariaDB** database backend, one need to extend Ansible configuration.

Let's now reflect some definitions into Kiwi's **ansible/inventories/group_vars/kiwi_eu_west/main.yml** configuration file:

```yaml
kowabunga_powerdns_locally_managed_zone_records:
  - zone: "{{ storage_domain_name }}"
    name: ceph
    value: 10.50.102.11
  - zone: "{{ storage_domain_name }}"
    name: ceph
    value: 10.50.102.12
  - zone: "{{ storage_domain_name }}"
    name: ceph
    value: 10.50.102.13
```

This will further instruct **PowerDNS** to handle local DNS zone for region **eu-west** on **acme.local** TLD.

Note that we'll use the **Kaktus** instances VLAN 102 IP addresses that we've defined in [network toplogy](/docs/getting-started/topology/) so that **ceph.storage.eu-west.acme.local** will be a round-robin DNS to these instances.

Finally, edit the SOPS-encrypted **ansible/inventories/group_vars/kiwi.sops.yml** file with newly defined secrets:

```yaml
secret_kowabunga_powerdns_webserver_password: ONE_STRONG_PASSWORD
secret_kowabunga_powerdns_api_key: ONE_MORE
secret_kowabunaga_powerdns_db_admin_password: YET_ANOTHER
secret_kowabunaga_powerdns_db_user_password: HERE_WE_GO
```

As names stand, first 2 variables will be used to expose **PowerDNS** API (which will be consumed by **Kiwi** agent) and last twos are MariaDB credentials, used by **PowerDNS** to connect to. None of these passwords really matter, they're server-to-server internal use only, no use is ever going to make use of them. But let's use something robust nonetheless.

## Kiwi Agent

Finally, let's take care of **Kiwi** agent. The agent will establish its secured WebSocket connection to **Kahuna**, receives configuration changes from, and apply accordingly.

Now remember that we previously used TF to [register new Kiwi agents](/docs/admin-guide/create-region/#kiwi-instances-and-agents). Once applied, emails were sent for each instance with a set of agent identifier and API key. These values now have to be provided to Ansible, as these are going to be the credentials used by **Kiwi** agent to connect to **Kahuna**.

So let's edit each Kiwi instance secrets file in respectively **ansible/inventories/host_vars/kiwi-eu-west-{1,2}.sops.yml** files:

```yaml
secret_kowabunga_kiwi_agent_id: AGENT_ID_FROM_KAHUNA_EMAIL_FROM_TF_PROVISIONING_STEP
secret_kowabunga_kiwi_agent_api_key: AGENT_API_KEY_FROM_KAHUNA_EMAIL_FROM_TF_PROVISIONING_STEP
```

## Ansible Deployment

We're finally done with **Kiwi**'s configuration. All we need to do now is finally run Ansible to make things live. This is done by invoking the **kiwi** playbook from the **kowabunga.cloud** collection:

```sh
$ kobra ansible deploy -p kowabunga.cloud.kiwi
```

We’re now ready for [provisionning Kaktus HCI nodes](/docs/admin-guide/create-kaktus/) !
