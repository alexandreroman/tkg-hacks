# Customizing cluster settings with Tanzu Kubernetes Grid

This document describes how you can customize your cluster, by overriding
values set in the Cluster-API definitions.

## How does it work?

When you create a cluster using `tkg create cluster`, the TKG CLI would
create Cluster-API definitions:
these definitions are then used when the cluster infrastructure is created.
The cluster configuration is built by assembling
different YAML files in `$HOME/.tkg/providers`.

The TKG CLI leverages [ytt](https://get-ytt.io/), a tool for manipulating
YAML definitions.

You can customize Cluster-API definitions by overriding objects from
`base-template.yaml`.

## Using YAML templating

Copy file `custom-cluster-settings.yaml` to
`$HOME/.tkg/providers/infrastructure-vsphere/ytt`.

In this sample, we apply new settings for the worker nodes, overriding
the `VSphereMachineTemplate` object used to describe worker VM:

```yaml
#@overlay/match by=overlay.subset({"kind": "VSphereMachineTemplate", "metadata": { "name": "foo-worker" }})
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha3
kind: VSphereMachineTemplate
spec:
  template:
    spec:
      diskGiB: 80
      memoryMiB: 8192
      numCPUs: 4
```

These settings would only be applied if your cluster is named `foo`.

Let's create a new cluster:

```bash
$ tkg create cluster -p dev foo
```

As worker nodes are created, you can see these settings have been applied
to these VMs.
