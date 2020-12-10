# Using Tanzu Kubernetes Grid with an HTTP proxy

This document describes how to enable HTTP proxy support when using
Tanzu Kubernetes Grid.

## How does it work?

The [ytt](https://get-ytt.io/) overlay is made of a single file: `http-proxy.yaml`.
This overlay enables HTTP proxy at the [containerd](https://containerd.io/) level.
All Docker images which are required to run your containers will be downloaded
through your HTTP proxy.

## Enabling HTTP proxy

Create directory `$HOME/.tkg/providers/ytt/04_user_customizations`.
All `ytt` overlays in this directory will be applied to all clusters.

Copy the file `http-proxy.yaml` to this directory.

Then, edit file `$HOME/.tkg/config_default.yaml`, and add these entries:

```yaml
#! HTTP proxy settings
#! ---------------------------------------------------------------------
HTTP_PROXY_HOST: "1.2.3.4"
HTTP_PROXY_PORT: "3128"
```

As you create your next cluster, the HTTP proxy is used to download images.

If you are actually about to create the Management Cluster, you also need to set up
the HTTP proxy settings before you run the `tkg init` command:

```bash
$ export "NO_PROXY=localhost,127.0.0.1,.svc,.cluster.local,$(cat $HOME/.tkg/config.yaml | yq r - VSPHERE_SERVER),$(cat $HOME/.tkg/config.yaml | yq r - HTTP_PROXY_HOST),$(cat $HOME/.tkg/config.yaml | yq r - CLUSTER_CIDR),$(cat $HOME/.tkg/config.yaml | yq r - SERVICE_CIDR)"
$ export "HTTP_PROXY=http://$(cat $HOME/.tkg/config.yaml | yq r - HTTP_PROXY_HOST):$(cat $HOME/.tkg/config.yaml | yq r - HTTP_PROXY_PORT)"
$ export "HTTPS_PROXY=$HTTP_PROXY"
$ export "http_PROXY=$HTTP_PROXY"
```
