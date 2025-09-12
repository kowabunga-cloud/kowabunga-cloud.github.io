---
title: Cloud-Init bootstrap
description: Customize your private Cloud instances.
weight: 1
---

Cloud images are operating system templates and every instance starts out as an identical clone of every other instance. It is the user data that gives every cloud instance its personality and [cloud-init](https://cloud-init.io/) is the tool that applies user data to your instances automatically.

Kowabunga **Kahuna** comes with pre-bundled [cloud-init templates](https://github.com/kowabunga-cloud/kowabunga/tree/master/config/templates) which are then deployed into **/etc/kowabunga/templates** configuration directory.

Supporting both Linux and Windows targets, they come with the usual:

- **meta_data.yml** file, providing various metadata information, that can be further reused by Kowabunga agents.
- **network_config.yml** file, allowing for proper automatic network stack and interfaces configuration.
-   **user_data.yml** file, providing a sequence of actions to be applied post (initial) boot, as described in its [standard documentation](https://cloudinit.readthedocs.io/en/latest/topics/examples.html).

Note that all these files are based on [Go Templates](https://pkg.go.dev/text/template). They are used by **Kahuna** to generate instance-specific configuration files and bundled into an ISO9660 image (stored on Ceph backend), ready to be consumed by OS, and written/updated each time a computing instance is being created/updated.

{{< alert color="warning" title="Warning" >}}
Kowabunga currently only provide admin-level **cloud-init** templating support. Templates are defined and maintained at admin level for the global platform. There's no present way to fine-tune **cloud-init** templates per project, as override.
{{< /alert >}}

## Linux Instances

Most of Linux distributions these days natively support **cloud-init** standard. As long as you're virtual machines boots up with an associated emulated CD-ROM ISO9660 image aside, you're good to go.

Note that Kowabunga **cloud-init** template natively provide the following post-actions:

- Setup network interfaces, DNS and gateway.
- Set instance hostname and FQDN.
- Update package repositories.
- Install basic packages, including QEMU agent.
- Set initial root password.
- Provision service user, ready to further bootstrap instance.
- Adds a **/usr/bin/kw-meta** wrapper script, friendly use to Kowabunga instance metadata retrieval.
- Wait for Internet connectivity/access.

## Microsoft Windows Instances

Microsoft Windows OS is a different story than Linux as there's no default **cloud-init** implementation bundled.

One can however cope with such limitation thanks to the [Cloudbase-Init](https://cloudbase.it/cloudbase-init/) project which provide **cloud-init** compatibility and is the "*The Quickest Way of Automating Windows Guest Initialization*". It supports Windows 8+ and Windows Server 2012+ OS variants.

Its usage implies a much more complex approach than Linux targets as it requires you to first [build up your private custom Windows disk image template](https://www.phillipsj.net/posts/building-a-windows-server-qcow2-image/), extending it with [cloudbase-init.conf](https://github.com/kowabunga-cloud/kowabunga/blob/master/config/cloudbase-init/cloudbase-init.conf) configuration file.

Once your image has been built, Kowabunga **cloudbase-init** supports all options from the [NoCloud](https://cloudbase-init.readthedocs.io/en/latest/services.html#nocloud-configuration-drive) engine.

Note that Kowabunga **cloudbase-init** template natively provide the following post-actions:

- Setup network interfaces, DNS and gateway.
- Set instance hostname and FQDN.
- Install basic packages, including NuGet, Paket, PsExec, OpenSSH.
- Set PowerShell as SSH default shell.
- Update firewall rules.
- Set OS password security policy.
- Set initial root password.
- Provision service user, ready to further bootstrap instance.

From there on, you'll get a ready-to-be-consumed Windows instance, which deployment can be further automated thanks to Ansible over SSH or any other provisioning tool or scripts.

It is then your responsibility to provide the Microsoft Windows license key (your Windows instance will anyway automatically shutdown after an hour if not).

{{< alert color="warning" title="Warning" >}}
Note that it is possible to bypass the license verification mechanism. This is only valid if you intend to use your instance as a temporary sandbox for development/testing purpose. Microsoft Windows licenses are not that expensive and **in no way does the Kowabunga project encourage piracy**.
{{< /alert >}}

Shall you be willing to temporarily bypass such mechanism, you can do so with such an Ansible playbook for instance:

```yaml
---
- hosts: windows

  vars:
    ansible_connection: ssh
    ansible_shell_type: powershell
    ansible_user: admin
    ansible_password: "SECURE_ADMIN_PASSWORD"

  tasks:
    - name: Accept EULA
      ansible.windows.win_shell: "PsExec.exe -accepteula"
      ignore_errors: true

    - name: Disable WLM
      ansible.windows.win_shell: "PsExec.exe \\\\127.0.0.1 -s -i sc config WLMS start=disabled"

    - name: Reboot hosts
      ansible.windows.win_shell: "shutdown /r"
```
