---
title: Setup Kahuna
description: Let's start with the orchestration core
weight: 2
---

Now let's suppose that your **Kahuna** instance server has been provisioned with latest Ubuntu LTS distribution. Be sure that it is SSH-accessible with some local user.

Let's take the following assumptions for the rest of this tutorial:

- We only have one single **Kahuna** instance (no high-availability).
- Local bootstrap user with **sudo** privileges is *ubuntu*, with key-based SSH authentication.
- **Kahuna** instance is public-Internet exposed through IP address *1.2.3.4*, translated to *kowabunga.acme.com* DNS.
- **Kahuna** instance is private-network exposed through IP address *10.0.0.1*.
- **Kahuna** instance hostname is **kowabunga-kahuna-1**.

## Setup DNS

Please ensure that your *kowabunga.acme.com* domain translates to public IP address *1.2.3.4*. Configuration is up to you and your DNS provider and can be done manually.

Being IaC-supporters, we advise using OpenTofu for that purpose. Let's see how we can do, using Cloudflare DNS provider.

Start by editing the **terraform/providers.tf** file in your platform's repository:

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "cloudflare" {
  api_token = local.secrets.cloudflare_api_token
}
```

extend the **terraform/secrets.tf** file with:

```hcl
locals {
  secrets = {
    cloudflare_api_token = data.sops_file.secrets.data.cloudflare_api_token
  }
}
```

and add the associated:

```yaml
cloudflare_api_token: MY_PREVIOUSLY_GENERATED_API_TOKEN
```

variable in **terraform/secrets.yml** file thanks to:

```sh
$ kobra secrets edit terraform/secrets.yml
```

Then, simply edit your **terraform/main.tf** file with the following:

```hcl
resource "cloudflare_dns_record" "kowabunga" {
  zone_id = "ACME_COM_ZONE_ID"
  name    = "kowabunga"
  ttl     = 3600
  type    = "A"
  content = "1.2.3.4"
  proxied = false
}
```

initialize OpenTofu  (once, or each time you add a new provider):

```sh
$ kobra tf init
```

and apply infrastructure changes:

```sh
$ kobra tf apply
```

## Ansible Kowabunga Collection

Kowabunga comes with an  official [Ansible Collection](https://galaxy.ansible.com/ui/repo/published/kowabunga/cloud/) and its associated [documentation](https://ansible.kowabunga.cloud/kowabunga/cloud/index.html#plugins-in-kowabunga-cloud).

The collection contains:

- **roles** and **playbooks** to easily deploy the various [Kahuna](/docs/concepts/kahuna/), [Koala](/docs/concepts/koala/), [Kiwi](/docs/concepts/kiwi/) and [Kaktus](/docs/concepts/kaktus/) instances.
- **actions** so you can create your own tasks to interact and manage a previously setup Kowabunga instance.

Check out **ansible/requirements.yml** file to declare the specific collection version you'd like to use:

```yaml
---
collections:
  - name: kowabunga.cloud
    version: 0.1.0
```

By default, your platform is configured to pull a tagged official release from Ansible Galaxy. You may however prefer to pull it directly from Git, using latest commit for instance. This can be accomodated through:

```yaml
---
collections:
  - name: git@github.com:kowabunga-cloud/ansible-collections-kowabunga
    type: git
    version: master
```

Once defined, simply pull it into your local machine:

```sh
$ kobra ansible pull
```

## Kahuna Settings

**Kahuna** instance deployment will take care of everything. It'll take the assumption of running a supported Ubuntu LTS release, enforce some configuration and security settings, install the necessary packages, create local admin user accounts, if required, and setup some form of deny-all filtering policy firewall, so you're safely exposed.

### Admin Accounts

Let's start by declaring some user admin accounts we'd like to create. We don't want to keep on using the single nominative **ubuntu** account for everyone after all.

Simply create/edit the **ansible/inventories/group_vars/all/main.yml** file the following way:

```yaml
kowabunga_os_user_admin_accounts_enabled:
  - admin_user_1
  - admin_user_2

kowabunga_os_user_admin_accounts_pubkey_dirs:
  - "{{ playbook_dir }}/../../../../../files/pubkeys"
```

to declare all your expected admin users, and add their respective SSH public key files in the **ansible/files/pubkeys** directory, e.g.:

```sh
$ tree ansible/files/pubkeys/
ansible/files/pubkeys/
└── admin_user_1
└── admin_user_2
```

{{< alert color="success" title="Note" >}}
Note that all registered admin accounts will have password-less **sudo** privileges.
{{< /alert >}}

We'd also recommend you to set/update the **root** account password. By default, Ubuntu comes without any, making it impossible to login. Kowabunga's playbook make sure that root login is prohibited from SSH for security reasons (e.g. brute-force attacks) but we encourage you setting one, as it's always useful, especially on public cloud VPS or bare metal servers to get a console/IPMI access to log into.

If you intend to do so, simply edit the secrets file:

```sh
$ kobra secrets edit ansible/inventories/group_vars/all.sops.yml
```

and set the requested password:

```yaml
secret_kowabunga_os_user_root_password: MY_SUPER_SETRONG_PASSWORD
```

### Firewall

If you **Kahuna** instance is connected on public Internet, it is more than recommended to enable a network firewall. This can be easily done by extending the **ansible/inventories/group_vars/kahuna/main.yml** file with:

```yaml
kowabunga_firewall_enabled: true
kowabunga_firewall_open_tcp_ports:
  - 22
  - 80
  - 443
```

Note that we're limited opened ports to SSH and HTTP/HTTPS here, which should be more than enough (HTTP is only used by **Caddy** server for certificate auto-renewal and will redirect traffic to HTTPS anyway). If you don't expect your instance to be SSH-accessible on public Internet, you can safely drop this line.

### MongoDB

**Kahuna** comes with a bundled, ready-to-be-used **MongoDB** deployment. This comes in handy if you only have a unique instance to manage. This remains however optional (default), as you may very well be willing to re-use an existing external production-grade MongoDB cluster, already deployed.

If you intend to go with the bundled one, a few settings must be configured in **ansible/inventories/group_vars/kahuna/main.yml** file:

```yaml
kowabunga_mongodb_enabled: true
kowabunga_mongodb_listen_addr: "127.0.0.1,10.0.0.1"
kowabunga_mongodb_rs_key: "{{ secret_kowabunga_mongodb_rs_key }}"
kowabunga_mongodb_rs_name: kowabunga
kowabunga_mongodb_admin_password: "{{ secret_kowabunga_mongodb_admin_password }}"
kowabunga_mongodb_users:
  - base: kowabunga
    username: kowabunga
    password: '{{ secret_kowabunga_mongodb_user_password }}'
    readWrite: true
```

and their associated secrets in **ansible/inventories/group_vars/kahuna.sops.yml**

```yaml
secret_kowabunga_mongodb_rs_key: YOUR_CUSTOM_REPLICA_SET_KEY
secret_kowabunga_mongodb_admin_password: A_STRONG_ADMIN_PASSWORD
secret_kowabunga_mongodb_user_password: A_STRONG_USER_PASSWORD
```

This will basically instruct Ansible to install MongoDB server, configure it with a replicaset (so it can be part of a future cluster instance, we never know), secure it with admin credentials of your choice and create a **kowabunga** database/collection and associated service user.

### Kahuna Settings

Finally, let's ensure the **Kahuna** orchestrator gets everything he needs to operate.

You'll need to define:

- a custom email address (and associated SMTP connection settings) for **Kahuna** to be able to send email notifications to users.
- a randomly generated key to sign JWT tokens (please ensure it is secure enough, not to compromise issued tokens robustness).
- a randomly generated admin API key. It'll be used to provision the admin bits of Kowabunga, until proper user accounts have been created.
- a private/public SSH key-pair to be used by platform admins to seamlessly SSH into instantiated [Kompute](/docs/user-guide/services/kompute/) instances. Please ensure that the private key is being stored securely somewhere.

Then simply edit the **ansible/inventories/group_vars/all/main.yml** file the following way:

```yaml
kowabunga_public_url: "https://kowabunga.acme.com"
```

(as variable will be reused by all instance types)

and the **ansible/inventories/group_vars/kahuna/main.yml** file the following way:

```yaml
kowabunga_kahuna_http_address: "10.0.0.1"
kowabunga_kahuna_admin_email: kowabunga@acme.com
kowabunga_kahuna_jwt_signature: "{{ secret_kowabunga_kahuna_jwt_signature }}"
kowabunga_kahuna_db_uri: "mongodb://kowabunga:{{ secret_kowabunga_mongodb_user_password }}@10.0.0.1:{{ mongodb_port }}/kowabunga?authSource=kowabunga"
kowabunga_kahuna_api_key: "{{ secret_kowabunga_kahuna_api_key }}"

kowabunga_kahuna_bootstrap_user: kowabunga
kowabunga_kahuna_bootstrap_pubkey: "YOUR_ADMIN_SSH_PUB_KEY"

kowabunga_kahuna_smtp_host: "smtp.acme.com"
kowabunga_kahuna_smtp_port: 587
kowabunga_kahuna_smtp_from: "Kowabunga <{{ kowabunga_kahuna_admin_email }}>"
kowabunga_kahuna_smtp_username: johndoe
kowabunga_kahuna_smtp_password: "{{ secret_kowabunga_kahuna_smtp_password }}"
```

and add the respective secrets into **ansible/inventories/group_vars/kahuna.sops.yml**:

```yaml
secret_kowabunga_kahuna_jwt_signature: A_STRONG_JWT_SGINATURE
secret_kowabunga_kahuna_api_key: A_STRONG_API_KEY
secret_kowabunga_kahuna_smtp_password: A_STRONG_PASSWORD
```

## Ansible Deployment

We're done with configuration (finally) ! All we need to do now is finally run Ansible to make things live. This is done by invoking the **kahuna** playbook from the **kowabunga.cloud** collection:

```sh
$ kobra ansible deploy -p kowabunga.cloud.kahuna
```

Note that, under-the-hood, Ansible will use [Ansible Mitogen extension](https://mitogen.networkgenomics.com/ansible_detailed.html) to speed things up. Bear in mind that Ansible's run is idempotent. Anything's failing can be re-executed. You can also run it as many times you want, or re-run it in the next 6 months or so, provided you're using a tagged collection, the end result will always be the same.

After a few minutes, if everything's went okay, you should have a working **Kahuna** instance, i.e.:

- A [Caddy](https://caddyserver.com/) frontal reverse-proxy, taking care of automatic TLS certificate issuance, renewal and traffic termination, forwarding requests back to either [Koala](/docs/concepts/koala/) Web application or [Kahuna](/docs/concepts/kahuna/) backend server.
- The [Kahuna](/docs/concepts/kahuna/) backend server itself, our core orchestrator.
- Optionally, [MongoDB](https://www.mongodb.com/) database.

We're now ready for [provisionning users and teams](/docs/admin-guide/provision-users/) !
