---
title: Koala
description: Learn about Koala Web application.
weight: 4
---

**Koala** is Kowabunga's WebUI. It allows for day-to-day supervision and operation of the various projects and services.

![](/docs/concepts/koala.png)

But should you ask a senior DevOps / SRE / IT admin, fully automation-driven, he'd damn anyone who'd have used the Web client to manually create/edit resources and messes around his perfecly maintained CasC.

We've all been there !!

That's why **Koala** has been designed to be read-only. While using Kowabunga's API, the project's directive is to enforce infrastructure and configuration as code, and such, prevents any means to do harm.

**Koala** is AngularJS based and usually located next to **Kahuna**'s instance. It provides users with capability to connect, check for the various projects (they belong to) resources, optionnally start/reboot/stop them and/or see various piece of information and ... that's it ;-)
