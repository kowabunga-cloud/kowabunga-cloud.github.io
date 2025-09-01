---
title: Create Your First Project
description: Let's bootstrap our new project.
weight: 1
---

In Kowabunga, a **project** is a virtual environment where all your resources are going to be created.

Projects can:

- be spawned over multiple **regions**. For each selected region, a dedicated **virtual network** and **subnet** will be automatically spawned (one from those created/reserved at admin provisioning stage). This ensures complete project's resources isolation.
- be **administrated** by multiple **teams** (e.g. the infrastructure admin one and the project application one).
- use **quotas** (maximum instances, vCPUs, memory, storage) to limit global HCI resources usage and starvation. A value of 0 means unlimited quota.
- use a private set of **bootstrap** keys (instead of global infrastructure one), so each newly created resource can be bootstraped with a specific keypair, until fully provisionned.
- The project default **admin/root password**, set at cloud-init instance bootstrap phase. Will be randomly auto-generated at each instance creation if unspecified.

As a **superAdmin** user, one can create a the **acme** project, for **admin** team members, limited to **eu-west** region, with unlimited resources quota, and requesting a /25 subnet (at least), the following way:

<!-- prettier-ignore-start -->
{{< tabpane >}}
{{< tab header="Code:" disabled=true />}}
{{< tab header="TF" lang="hcl" >}}
data "kowabunga_region" "eu-west" {
  name = "eu-west"
}

data "kowabunga_team" "admin" {
  name = "admin"
}

resource "kowabunga_project" "acme" {
  name          = "acme"
  desc          = "ACME project"
  regions       = [data.kowabunga_region.eu-west.id]
  teams         = [data.kowabunga_team.admin.id]
  domain        = "acme.local"
  tags          = ["acme", "production"]
  metadata      = {
    "owner": "Kowabunga Admin",
  }
  max_instances = 0
  max_memory    = 0
  max_vcpus     = 0
  max_storage   = 0
  subnet_size   = 25
}
{{< /tab >}}
{{< tab header="Ansible" lang="yaml" >}}
- name: Create ACME project
  kowabunga.cloud.project:
    name: acme
    description: "ACME project"
    regions:
      - eu-west
    teams:
      - admin
    domain: "acme.local"
    subnet_size: 25
    state: present
{{< /tab >}}
{{< /tabpane >}}
<!-- prettier-ignore-end -->

Your project is now live and does virtually nothing. Let's move further by creating our first resource, the [Kawaii Internet Gateway](/docs/user-guide/services/kawaii/).
