---
title: Kahuna
description: Learn about Kahuna orchestrator.
weight: 3
---

**Kahuna** is Kowabunga's orchestration system. Its name takes root from Hawaiian's **(Big) Kahuna** word, meaning *"the expert, the most dominant thing"*.

**Kahuna** remotely controls every resource and maintains ecosystem consistent. It's the gateway to Kowabunga REST API.

From a technological stack perspective, **Kahuna** features:

- a [Caddy](https://caddyserver.com/) public HTTPS frontend, reverse-proxying requests to:
  - [Koala](/docs/concepts/koala/) Web application, or
  - **Kahuna** orchestrator daemon
- a [MongoDB](https://www.mongodb.com/) database backend.

The **Kahuna** orchestrator features:

- **Public REST API handler**: implements and operates the API calls to manage resources,interacting with rightful local agents through JSON-RPC over WSS.
- **Public WebSocket handler**: agent connection manager, where the various agents establish secure WebSocket tunnels to, for being further controlled, bypassing on-premises firewall constraints and preventing the need of any public service exposure.
- **Metadata endpoint**: where managed virtual instances and services can retrieve information services and self-configure themselves.

Kowabunga API folds into 2 type of assets:

- **admin** ones, used to handle objects like region, zone, kaktus and kiwi hosts, agents, networks ...
- **user** ones, used to handle objects such as **Kompute**, **Kawaii**, **Konvey** ...

**Kahuna** implements robust RABC and segregation of duty as to ensure access boundaries, such as:

- Nominative RBAC capabilities and per-organization and team user management.
- Per-project teams associationfor per-resource access control.
- Support for both JWT bearer (human-to-server) and API-Key token-based (server-to-server) authentication mechanisms.
- Support for 2-steps account creation/validation and enforced robust passwords/tokens usage(server-generated, user-input is prohibited).
- Nominative robust HMAC ID+token credentials over secured WebSocket agent connections.

This ensures that:

- only rightful designated agents are able to establish WSS connections with **Kahuna**
- created virtual instances can only retrieve the metadata profile they belong to (and self configure or update themselves at boot or runtime).
- users can only see and manage resources for the projects they belong to.

{{< alert color="warning" title="Warning" >}}
Despite being central, **Kahuna**'s implementation does not yet allow for stateless distribution.

The current design with DB caches and WebSocket connection makes it hard to distribute without involving a message queue middleware. This is a good problem for the future, but not for now. A single Kahuna instance is perefeclty capable of handling multiple thousands of concurrent connections, which we believe to be more than enough for a private platform orchestrator (it wouldn't for a large-scale public Cloud one).

Providing **Kahuna** with high-availability remains however fully possible, using good-old active-passive failover mechanism.
{{< /alert >}}
