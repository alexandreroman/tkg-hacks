# Creating cluster addons for Tanzu Kubernetes Grid

In this document, check out how to add custom addons to your
Tanzu Kubernetes Grid clusters. As you create new clusters, these
addons are automatically added.

## How does it work?

In the Cluster-API specification, you create
[ClusterResourceSet](https://cluster-api.sigs.k8s.io/tasks/experimental-features/cluster-resource-set.html)
entities to deploy resources (configuration, secrets, applications) at cluster creation.

In this example, a cluster addon for Prometheus is defined as a `ClusterResourceSet`.

File `prometheus-addon.yaml` contains the Cluster-API resources: it also imports
file `prometheus.lib.yaml` which includes all Prometheus definitions.

Using [ytt](https://get-ytt.io/) templating, the Cluster-API resources are built
by including the Prometheus resources, taking care of indenting YAML objects.

## Deploying a cluster addon

Create directory `$HOME/.tkg/providers/ytt/04_user_customizations`.
All `ytt` overlays in this directory will be applied to all clusters.

Copy files `prometheus-addon.yaml` and `prometheus.lib.yaml` to this directory.

As you create your next cluster, this cluster addon will automatically be deployed:

```bash
$ tkg create cluster foo -w 1 -p dev --vsphere-controlplane-endpoint-ip 10.213.167.60
Logs of the command execution can also be found at: /tmp/tkg-20201130T203214643053607.log
Validating configuration...
Creating workload cluster 'foo'...
Waiting for cluster to be initialized...
Waiting for cluster nodes to be available...
Waiting for addons installation...

Workload cluster 'foo' created
```

Prometheus has been deployed leveraging Cluster-API and `ClusterResourceSet`:

```bash
$ kubectl -n monitoring get pods
NAME                                     READY   STATUS    RESTARTS   AGE
prometheus-deployment-5944c8497d-zbv95   1/1     Running   0          9m
```
