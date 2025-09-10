---
title: Provisioning Users
description: Let's populate admin users and teams
weight: 3
---

Your **Kahuna** instance is now up and running, let's get things and create a few admin users accounts. At first, we only have the super-admin API key that was previously set through Ansible deployment. We'll make use of it to provision further users and associated teams. After all, we want a nominative user acount for each contributor, right ?

Back to TF config, let's edit the **terraform/providers.tf** file:

```hcl
terraform {
  required_providers {
    kowabunga = {
      source  = "kowabunga-cloud/kowabunga"
      version = ">=0.55.0"
    }
  }
}

provider "kowabunga" {
  uri   = "https://kowabunga.acme.com"
  token = local.secrets.kowabunga_admin_api_key
}
```

Make sure to edit the Kowabunga provider's **uri** with the associated DNS of your freshly deployed **Kahuna** instance and edit the **terraform/secrets.yml** file so match the **kowabunga_admin_api_key** you've picked before. OpenTofu will make use of these parameters to connect to your private **Kahuna** and apply for resources.

Now declare a few users in your **terraform/locals.tf** file:

```hcl
locals {
  admins = {
    // HUMANS
    "John Doe" = {
      email  = "john@acme.com",
      role   = "superAdmin",
      notify = true,
    }
    "Jane Doe" = {
      email  = "jane@acme.com",
      role   = "superAdmin",
      notify = true,
    }

    // BOTS
    "Admin TF Bot" = {
      email = "tf@acme.com",
      role  = "superAdmin",
      bot   = true,
    }
  }
}
```

and the following resources definition in **terraform/main.tf**:

```hcl
resource "kowabunga_user" "admins" {
  for_each      = local.admins
  name          = each.key
  email         = each.value.email
  role          = each.value.role
  notifications = try(each.value.notify, false)
  bot           = try(each.value.bot, false)
}

resource "kowabunga_team" "admin" {
  name  = "admin"
  desc  = "Kowabunga Admins"
  users = sort([for key, user in local.admins : kowabunga_user.users[key].id])
}
```

Then, simply apply for resources creation:

```sh
$ kobra tf apply
```

What we've done here was to register a new **admin** team, with 3 new associated user accounts: 2 regular ones for human administrators and one **bot**, which you'll be able to use its API key instead of the super-admin master one to further provision resources if you'd like.

Better do this way as, shall the key be compromised, you'll only have to revoke it or destroy the bot account, instead of replacing the master one on **Kahuna** instance.

Newly registered user will be prompted with 2 emails from **Kahuna**:

- a "**Welcome to Kowabunga !**" one, simply asking yourself to confirm your account's creation.
- a "**Forgot about your Kowabunga password ?**" one, prompting for a password reset.

{{< alert color="warning" title="Warning" >}}
Account's creation confirmation is required for the user to proceed further. For security purpose, newly created user accounts are locked-down until properly activated.

With security in mind, Kowabunga will prevent you from setting your own password. Whichever IT policy you'd choose, you will always end up with users having a weak password or finding a way to compromise your system. We don't want that to happen, nor do we think it's worth asking a user to generate a random 'strong-enough' password by himself, so Kowabunga does it for you.
{{< /alert >}}

Once users have been registered and password generated, and provided **Koala** Web application has been deployed as well, they can connect to (and land on a perfectly empty and so useless dashboard ;-) for now at least ).

Let's move on and start [creating our first region](/docs/admin-guide/create-region/) !
