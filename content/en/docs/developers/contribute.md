---
title: Contributing
description: Learn how to controbute to Kowabunga
weight: 1
---

## Kowabunga API

It's all about API ;-)

Kowabunga implements a full [OpenAPI v3](https://swagger.io/specification/) compliant [API](https://kowabunga.cloud/api/).

Starting you journey with Kowabunga an extending its capabilities and features take its roots in [API definition](https://github.com/kowabunga-cloud/openapi)

Our API build tools rely on some heavily tuned Jinja macros to factorize code as much as can be.

While we try to keep as much compatibility as can be, Kowabunga's API is not yet frozen (and won't before reaching 1.0 stage) and can still evolve. Our API is designed to be self-consumed by the **Kahuna** server and all code-generated SDK libaries.

## Orchestrator and Agents

Server-side and standalone agents (**Kiwi**, **Kaktus** but also service ones, like **Kawaii**, **Konvey** and others ...) are all managed in a single [source repository](https://github.com/kowabunga-cloud/kowabunga).

They are build with love in [Go](https://go.dev/) programming language.

### Linux Requirements

On Ubuntu 24.04, you fundamentaly need Ceph librairies (Rados/RBD):

```sh
$ sudo apt-get update
$ sudo apt-get install -y gcc librados-dev librbd-dev
```

and a Go compiler:

```sh
$ sudo apt-get install -y golang-1.23
```

even though it is recommended to always use [latest up-to-date release](https://go.dev/dl/) from which Kowabunga's development is always based on.

### macOS Requirements

macOS requires Ceph librairies from Homebrew project:

```sh
$ brew tap mulbc/ceph-client
$ brew install ceph-client
```

{{< alert color="warning" title="Warning" >}}
Note that macOS ceph-client is currently outdate and prevents us from using [go-ceph](https://github.com/ceph/go-ceph/tree/master) v0.34.0+ bindings ;-(

Anyone willing to update the tap would be a lifesaver ;-)
{{< /alert >}}

and latest Go compiler:

```sh
$ brew install go
```

### Build

Building all Kowabunga binaries is as simple as:

```sh
$ make
```

One can also check for [secure programming checks](https://securego.io/) through:

```sh
$ make sec
```

and check for known (to-date) [vulnerabilities](https://go.dev/doc/security/vuln/) through:

```sh
$ make vuln
```

## Koala WebUI

Our WebUI, [Koala](https://github.com/kowabunga-cloud/koala) is made with [Angular](https://angular.dev/) and actively looking for contributors and maintainers ;-)

Kowabunga's purpose being to enforce automation-as-code and configuration-as-code, **Koala** is designed to be user-facing, yet read-only.
