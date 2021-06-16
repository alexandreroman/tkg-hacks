# Installing Tanzu Kubernetes Grid in offline scenarios

This set of scripts allows you to download TKG images from Internet.
The idea is to store these images on your disk, and then upload
these images to your private Docker registry. This way, you'll be able
to install TKG without relying on an Internet connection.

## Downloading TKG images

You are about to download Docker images to your workstation.
You need the following tools:

- [yq](https://github.com/mikefarah/yq) - a CLI tool to parse YAML files
- [imgpkg](https://carvel.dev/imgpkg/) - a CLI tool to download and upload container images
- [tanzu](https://my.vmware.com/web/vmware/details?downloadGroup=TKG-131&productId=1165) - the Tanzu CLI

Make sure you have [initialized the Tanzu CLI first (including TKG plugins)](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-install-cli.html).

Running these commands will create the TKG configuration files:

```bash
$ tanzu init
$ tanzu management-cluster create
```

Pick the Kubernetes versions you want to download:

```bash
$ imgpkg tag list -i projects.registry.vmware.com/tkg/tkr-bom
Tags

Name                     Digest
v1.19.9_vmware.2-tkg.1   sha256:1affd1ae18a5ff7732ba933b490b755a33d1e35ea5c4e8b68a83d8ee05de448e
v1.20.5_vmware.2-tkg.1   sha256:37f905175390516dd20a8aacdafc91d6e9f10fc58abf6e4b9f9c416b9d4c8ac7

2 tags

Succeeded
```

Run this script to download images:

```bash
$ ./tkg-download-images.sh -k v1.20.5_vmware.2-tkg.1
```

In case you want to include more images, just use the `-i` argument:

```bash
$ ./tkg-download-images.sh -k v1.20.5_vmware.2-tkg.1 -i metallb/speaker:v0.10.2 -i metallb/controller:v0.10.2
```

When the script is done, the images are stored as TAR files. There's also
a manifest file named `manifest.yml`.

Copy those files to your air-gapped environment.

## Uploading TKG images to your private Docker registry

At this point, you don't need Internet access. All you need is network access to your private registry.

Run this script to upload TKG images:

```bash
$ ./tkg-upload-images.sh -r harbor.tanzu.local
```

You're done!

Don't forget to set `TKG_CUSTOM_IMAGE_REPOSITORY` and `TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE`
in `$HOME/.tanzu/tkg/config.yaml`,
[as described in the documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-mgmt-clusters-airgapped-environments.html#step-5-initialize-tanzu-kubernetes-grid-9).
