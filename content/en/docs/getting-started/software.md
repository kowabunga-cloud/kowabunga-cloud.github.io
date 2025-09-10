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

Installation can be easily performed on various targets:

### Installation Ubuntu Linux

Register [Kowabunga APT repository](https://packages.kowabunga.cloud/) and then simply:

```sh
$ sudo apt-get install kobra
```

### Installation on macOS

macOS can install **Kobra** through [Homebrew](https://brew.sh/). Simply do:

```sh
$ brew tap kowabunga/cloud https://github.com/kowabunga-cloud/homebrew-tap.git
$ brew update
$ brew install kobra
```

### Manual Installation

**Kobra** can be manually installed through [released binaries](https://github.com/kowabunga-cloud/kobra/releases).

Just download and extract the tarball for your target.

{{< alert color="success" title="Tips" >}}
Note that **kobra** is a simple wrapper around your favorite tools. If things don't go as planned, you can turn on the debug flag, which will comes in handy (or simply show you what exact caommand-line is being invoked), e.g.

```sh
$ KOBRA_DEBUG=1 kobra ...
```
{{< /alert >}}

## Setup Git Repository

Kowabunga comes with a ready-to-consumed platform template. One can clone it from Git through:

```sh
$ git clone https://github.com/kowabunga-cloud/platform-template.git
```

or better, fork it in your own account, as a boostraping template repository.

## Secrets Management

Passwords, API keys, tokens ... they are all sensitive and meant to be secrets. You don't want any of those to leak on a public Git repository. **Kobra** relies on [SOPS](https://getsops.io/) to ensure all secrets are located in an encrypted file (which is safe to to be Git hosted), which can be encrypted/decrypted on the fly thanks to a master key.

**Kobra** supports various key providers:

- **aws**: AWS Secrets Manager
- **env**: Environment variable stored master-key
- **file**: local plain text master-key file (not recommended for production)
- **hcp**: Hashicorp Vault
- **input**: interactive command-line input prompt for master-key
- **keyring**: local OS keyring (macOS Keychain, Windows Credentials Manager, Linux Gnome Keyring/KWallet)

If you're building a large production-grade system, with multiple contributors and admins, using a shared key management system like **aws** or **hcp** is probably welcome.

If you're single contributor or in a very small team, storing your master encryption key in your local **keyring** will do just fine.

Simply edit your **kobra.yml** file in the following section:

```yaml
secrets:
  provider: string                    # aws, env, file, hcp, input, keyring
  aws:                                # optional, aws-provider specific
    region: string
    role_arn: string
    id: string
  env:                                # optional, env-provider specific
    var: string                       # optional, defaults to KOBRA_MASTER_KEY
  file:                               # optional, file-provider specific
    path: string
  hcp:                                # optional, hcp-provider specific
    endpoint: string                  # optional, default to "http://127.0.0.1:8200" if unspecified
  master_key_id: string
```

As an example, managing platform's master key through your system's keyring is as simple as:

```yaml
secrets:
  provider: keyring
  master_key_id: my-kowabunga-labs
```

As a one-time thing, let's init our new SOPS key pair.

```sh
$ kobra secrets init
 ▶ [INFO 00001] Issuing new private/public master key ...
 ▶ [INFO 00002] New SOPS private/public key pair has been successuflly generated and stored
```

{{< alert color="warning" title="Warning" >}}
If you've lost this master key, your whole system becomes compromised.

There's no way to restore it.

We more than **heavily recommend** you to backup the generated master key in a secondary vault of your choice.

You can easily extract the base64-encoded key through:

```sh
$ kobra secrets get --yes-i-really-mean-it
```

Alternatively, you can share it with a contributor or have it re-imported (or rotated) through:

```sh
kobra secrets set --yes-i-really-mean-it -k MY_BASE64_ENCODED_MASTER_KEY
```
{{< /alert >}}

### Ansible

The official [Kowabunga Ansible Collection](https://galaxy.ansible.com/ui/repo/published/kowabunga/cloud/) and its associated [documentation](https://ansible.kowabunga.cloud/kowabunga/cloud/index.html#plugins-in-kowabunga-cloud) will seamlessly integrate with SOPS for secrets management.

Thanks to that, any file from your inventory's **host_vars** or **group_vars** directories, being suffixed as **.sops.yml** will automatically be included when running playbooks. It is then absolutely safe for you to use these encrypted-at-rest files to store your most sensitive variables.

Creating such files and/or editing these to add extra variables is then as easy as:

```sh
$ kobra secrets edit ansible/inventories/group_vars/all.sops.yml
```

**Kobra** will automatically decrypt the file in-live, open the editor of your choice (as stated in your **$EDITOR** env var), and re-ecnrypt it with the master key at save/exit.

That's it, you'll never have to worry about secrets management and encryption any longer !

### OpenTofu

The very same applies for **OpenTofu**, where SOPS master key is used to encrypt the most sensitive data. Anything sensitive you'd need to add to your TF configuration can be set in the **terraform/secrets.yml** file as simple key/value.

```sh
$ kobra secrets edit terraform/secrets.yml
```

Note however that their existence must be manually reflected into HCL formatted **terraform/secrets.tf** file, e.g.:

```hcl
locals {
  secrets = {
    my_service_api_token = data.sops_file.secrets.data.my_service_api_token
  }
}
```

supposing that you have an encrypted **my_service_api_token: ABCD...Z** entry in your **terraform/secrets.yml** file.

Note that **OpenTofu** adds a very strong feature over plain old **Terraform**, being TF state file encryption. Where the TF state file is located (local, i.e. Git or remotely, S3 or alike) is up to you, but shall you use a Git located one, we **strongly** advise to have it encrypted.

You can achieve this easily by extending the **terraform/providers.tf** file in your platform's repository:

```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.passphrase
    }

    method "aes_gcm" "sops" {
      keys = key_provider.pbkdf2.passphrase
    }
    state {
      method = method.aes_gcm.sops
    }

    plan {
      method = method.aes_gcm.sops
    }
  }
}

variable "passphrase" {
  # Value to be defined in your local passphrase.auto.tfvars file.
  # Content to be retrieved from decyphered secrets.yml file.
  sensitive = true
}
```

Then, create a local **terraform/passphrase.auto.tfvars** file with the secret of your choice:

```hcl
passphrase = "ABCD...Z"
```

{{< alert color="warning" title="Warning" >}}
Note that you don't want the **terraform/passphrase.auto.tfvars** (being plain-text) file to be stored on Git, so make sure it is well ignored in your **.gitignore** configuration.

Also, it's strongly advised that whatever passphrase you'd chose to encrypt TF state is kept secure. A good practice would be to have it copied and defined in **terraform/secrets.yml** file, as any other sensitive variable, so to keep it vaulted.
{{< /alert >}}
