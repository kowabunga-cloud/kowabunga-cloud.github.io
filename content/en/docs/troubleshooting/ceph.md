---
title: Ceph
description: Troubleshooting Ceph storage
weight: 11
---

Kaktus HCI nodes rely on [Ceph](https://ceph.io/en/) for underlying distributed storage.

Ceph provides both:

- RBD block-device images for **Kompute** virtual instances
- CephFS distributed file system for **Kylo** storage.

Ceph is awesome. Ceph is fault-tolerant. Ceph hashes your file objects into thousands of pieces, distributed and replicated over dozens if not hundreds of SSDs on countless machines. And yet, Ceph sometimes crashes or fails to recover (even though it has incredible self healing capabilities).

While Ceph perfeclty survives some occasional nodes failure, have a try when you have a complete network or power-supply outage in your region, and you'll figure it out ;-)

So let's so how we can restore Ceph cluster.

## Unable to start OSDs

If Ceph OSDs can't be started, it is likely because of un-detected (and un-mounted) LVM partition.

A proper **mount** command should provide the following:

```sh
$ mount | grep /var/lib/ceph/osd
tmpfs on /var/lib/ceph/osd/ceph-0 type tmpfs (rw,relatime,inode64)
tmpfs on /var/lib/ceph/osd/ceph-2 type tmpfs (rw,relatime,inode64)
tmpfs on /var/lib/ceph/osd/ceph-1 type tmpfs (rw,relatime,inode64)
tmpfs on /var/lib/ceph/osd/ceph-3 type tmpfs (rw,relatime,inode64)
```

If not, that means that **/var/lib/ceph/osd/ceph-X** directories are empty and OSD can't run.

Run the following command to re-scan all LVM partitions, remount and start OSDs.

```sh
$ sudo ceph-volume lvm activate --all
```

Check for **mount** output (and/or re-run command) until all target disks are mounted.

## Fix damaged filesystem and PGs

In case of health error and damaged filesystem/PGs, one can easily fix those:

```sh
$ ceph status

  cluster:
    id:     be45512f-8002-438a-bf12-6cbc52e317ff
    health: HEALTH_ERR
            25934 scrub errors
            Possible data damage: 7 pgs inconsistent
```

Isolate the damaged PGs:

```sh
$ ceph health detail
HEALTH_ERR 25934 scrub errors; Possible data damage: 7 pgs inconsistent
[ERR] OSD_SCRUB_ERRORS: 25934 scrub errors
[ERR] PG_DAMAGED: Possible data damage: 7 pgs inconsistent
    pg 2.16 is active+clean+scrubbing+deep+inconsistent+repair, acting [5,11]
    pg 5.20 is active+clean+scrubbing+deep+inconsistent+repair, acting [8,4]
    pg 5.26 is active+clean+scrubbing+deep+inconsistent+repair, acting [11,3]
    pg 5.47 is active+clean+scrubbing+deep+inconsistent+repair, acting [2,9]
    pg 5.62 is active+clean+scrubbing+deep+inconsistent+repair, acting [8,1]
    pg 5.70 is active+clean+scrubbing+deep+inconsistent+repair, acting [11,2]
    pg 5.7f is active+clean+scrubbing+deep+inconsistent+repair, acting [5,3]
```

Proceed with PG repair (iterate on all inconsistent PGs):

```sh
$ ceph pg repair 2.16
````

and wait until everything's fixed.

```sh
$ ceph status
  cluster:
    id:     be45512f-8002-438a-bf12-6cbc52e317ff
    health: HEALTH_OK
```

## MDS daemon crashloop

If your Ceph MDS daemon (i.e. CephFS) is in a crashloop, probably because of corrupted journal, let's see how we can proceed:

### Get State

Check for global CephFs status, including clients list, number of active MDS servers etc ...

```sh
$ ceph fs status
```

Additionnally, you can get a dump of all filesystem, trying to find MDS daemons' status (laggy, replay ...):

```sh
$ ceph fs dump
```

### Prevent client connections

If you suspect the filesystem's to be damaged, first thing to do is to preserve any more corruption.

Start by stopping all CephFs clients, if under control.

For Kowabunga, that means stopping NFS Ganesha server on all Kaktus instances:

```sh
$ sudo systemctl stop nfs-ganesha
```

Prevent all client connections from server-side (i.e. Kaktus).

We consider that filesystem name is **nfs**:

```sh
$ ceph config set mds mds_deny_all_reconnect true
$ ceph config set mds mds_heartbeat_grace 3600
$ ceph fs set nfs max_mds 1
$ ceph fs set nfs refuse_client_session true
$ ceph fs set nfs down true
```

Stop server-side MDS instances on all Kaktus servers:

```sh
$ sudo systemctl stop ceph-mds@$(hostname)
```

### Fix metadata journal

You may refer to [Ceph Troubleshooting guide](https://docs.ceph.com/en/latest/cephfs/disaster-recovery-experts/) for more details on disaster recovery.

Start backing up journal:

```sh
$ cephfs-journal-tool --rank nfs:all journal export backup.bin
```

Inspect journal:

```sh
$ cephfs-journal-tool --rank nfs:all journal inspect
```

Then proceed with dentries recovery and journal truncation

```sh
$ cephfs-journal-tool --rank=nfs:all event recover_dentries summary
$ cephfs-journal-tool --rank=nfs:all journal reset
```

Optionally reset session entries:

```sh
$ cephfs-table-tool all reset session
$ ceph fs reset nfs --yes-i-really-mean-it
```

Verify Ceph MDS can be brought up again:

```sh
$ sudo /usr/bin/ceph-mds -f --cluster ceph --id $(hostname) --setuser ceph --setgroup ceph
````

If ok, then kill it ;-) (Ctrl+C)

### Resume Operations

Flush all OSD blocklisted MDS clients:

```sh
$ for i in $(ceph osd blocklist ls 2>/dev/null | cut -d ' ' -f 1); do ceph osd blocklist rm $i; done
```

Ensure we're all fine:

```sh
$ ceph osd blocklist ls
```

There should be no entry anymore.

Start server-side MDS instances on all Kaktus servers:

```sh
$ sudo systemctl start ceph-mds@$(hostname)
```

Enable back client connections:

```sh
$ ceph fs set nfs down false
$ ceph fs set nfs max_mds 2
$ ceph fs set nfs refuse_client_session false
$ ceph config set mds mds_heartbeat_grace 15
$ ceph config set mds mds_deny_all_reconnect false
```

Start back all CephFs clients, if under control.

For Kowabunga, that means starting NFS Ganesha server on all Kaktus instances:

```sh
$ sudo systemctl start nfs-ganesha
```
