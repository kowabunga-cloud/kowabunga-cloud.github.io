---
title: Software Requirements
description: Get your toolchain ready
weight: 2
---

Kowabunga's deployment philosophy relies on IaC (Infrastructure-as-Code) and CasC (Configuration-as-Code). We heavily rely on:

- [Terraform](https://developer.hashicorp.com/terraform) or better, [OpenTofu](https://opentofu.org/) for IaC
- [Ansible](https://www.ansible.com/) for CasC.

## Kobra Toolchain

While natively compatible with the aformentionned, we recommend using [Kowabunga Kobra](https://github.com/kowabunga-cloud/kobra) as a toolchain overlay.

**Kobra** is a DevOps deployment swiss-army knife utility. It provides a convenient wrapper over **OpenTofu**, **Ansible** and **Helmfile** with proper secrets management, removing the hassle of complex deployment startegy.

Anything can be done without **Kobra**, but it makes things simpler, not having to care about the gory details.

**Kobra** supports various secret management providers. Please choose that fits your expected collaborative work experience.

At runtime, it'll also make sure you're **OpenTofu** / **Ansible** toolchain is properly set on your computer, and will do so otherwise (i.e. brainless setup).

## Setup Git Repository

Kowabunga comes with a ready-to-consumed platform template. One can clone it from Git through:

```sh
$ git clone https://
```

or better, fork it in your own account, as a boostraping template repository.
