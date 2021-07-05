# Adding files to Tanzu Kubernetes Grid nodes

This overlay shows how to add files to TKG nodes,
leveraging Cluster-API object definitions.

## How does it work?

Create directory `$HOME/.tanzu/tkg/providers/ytt/04_user_customizations`.
All `ytt` overlays in this directory will be applied to all clusters.

Copy files `custom-files.yaml` and `hello.txt` to this directory.

As you create your next cluster, this cluster overlay will automatically be deployed:

```bash
$ tanzu cluster create foo -f foo-cluster-config.yaml
Logs of the command execution can also be found at: /tmp/tkg-20201130T203214643053607.log
Validating configuration...
Creating workload cluster 'foo'...
Waiting for cluster to be initialized...
Waiting for cluster nodes to be available...
Waiting for addons installation...

Workload cluster 'foo' created
```

Now let's see if the new files have been created in the control plane node:
```bash
$ ssh capv@controlplane_ip_address cat /etc/hello.txt
Hello world!
$ ssh capv@controlplane_ip_address sudo cat /etc/secret.txt
This is a secret file loaded from a Kubernetes Secret object.
```

New files have been created in worker nodes too:
```bash
$ ssh capv@worker_ip_address cat /etc/hello.txt
Hello world! - inline content
$ ssh capv@worker_ip_address sudo cat /etc/secret.txt
This is a secret file loaded from a Kubernetes Secret object.
```

Note that the file `/etc/secret.txt` has been created from a Kubernetes `Secret` object.
The content is shared across cluster nodes.
