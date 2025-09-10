---
title: Inventory Management
description: Declaring Infrastructure Assets
weight: 1
---

Now let's suppose that you've cloned the Git platform repository template.

## Inventory Management

It is now time to declare your various instances in Ansible's inventory. Simply extend the **ansible/inventories/hosts.txt** the following way:

```ini
##########
# Global #
##########

[kahuna]
kowabunga-kahuna-1 ansible_host=10.0.0.1 ansible_ssh_user=ubuntu

##################
# EU-WEST Region #
##################

[kiwi_eu_west]
kiwi-eu-west-1 ansible_host=10.50.101.2
kiwi-eu-west-2 ansible_host=10.50.101.3

[kaktus_eu_west]
kaktus-eu-west-a-1 ansible_host=10.50.101.11
kaktus-eu-west-a-2 ansible_host=10.50.101.12
kaktus-eu-west-a-3 ansible_host=10.50.101.13

[eu_west:children]
kiwi_eu_west
kaktus_eu_west

################
# Dependencies #
################

[kiwi:children]
kiwi_eu_west

[kaktus:children]
kaktus_eu_west
```

In this example, we've declared our 6 instances (1 global **Kahuna**, 2 **Kiwi** and 3 **Kaktus** from EU-WEST region and their respective associated private IP addresses (used to deploy through SSH).

They respectively belong to various groups, and we've also created sub-groups. This is a special Ansible trick which will allow us to inherit variables from group each instance belongs to.

In that regard, considering the example of **kaktus-eu-west1**, the instance will be assigned variables from possibly various files. You can then safely:

- declare host-specific variables in **ansible/host_vars/kaktus-wu-west-1.yml** file.
- declare host-specific sensitive variables in **ansible/host_vars/kaktus-eu-west-1.sops.yml** file.
- declare **kaktus_eu_west** group-specific variables in **ansible/group_vars/kaktus_eu_west/main.yml** file.
- declare **kaktus_eu_west** group-specific sensitive variables in **ansible/group_vars/kaktus_eu_west.sops.yml** file.
- declare **kaktus** group-specific variables in **ansible/group_vars/kaktus/main.yml** file.
- declare **kaktus** group-specific sensitive variables in **ansible/group_vars/kaktus.sops.yml** file.
- declare **eu_west** group-specific variables in **ansible/group_vars/kaktus/eu_west.yml** file.
- declare **eu_west** group-specific sensitive variables in **ansible/group_vars/eu_west.sops.yml** file.
- declare any other global variables in **ansible/group_vars/all/main.yml** file.
- declare any other global sensitive variables in **ansible/group_vars/all.sops.yml** file.

This way, instance can inherit variables from its global type (**kaktus**), its region (**eu_west**), and a mix of both (**kaktus_eu_west**).

Note that [Ansible variables precedence](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence) will apply:

```txt
role defaults < all vars < group vars < host vars < role vars
```

Let's take the time to also update the **ansible/inventories/group_vars/all/main.yml** file to update a few settings:

```yaml
kowabunga_region_domain: "{{ kowabunga_region }}.acme.local"
```

where **acme.local** would be your corporate private domain.
