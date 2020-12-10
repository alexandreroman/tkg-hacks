# Installing Tanzu Kubernetes Grid to an offline environment

This set of scripts allows you to download TKG images from Internet.
The idea is to store these images on your disk, and then upload
these images to your private Docker registry. This way, you'll be able
to install TKG without relying on an Internet connection.

## Downloading TKG images

You are about to download Docker images to your workstation.
You need the following tools:

- a Docker daemon running - you may use [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [yq](https://github.com/mikefarah/yq) - a CLI tool to parse YAML files
- [jq](https://stedolan.github.io/jq/) - a CLI tool to parse JSON files
- [tkg](https://www.vmware.com/go/get-tkg) - the TKG CLI

First, you must run the TKG CLI in order to initialize the configuration files:
```bash
$ tkg get mc
```

The TKG configuration files are now available in `$HOME/.tkg`.

Run this script to download images:

```bash
$ ./tkg-download-images.sh -r myprivaterepo.company.com/tkg
```

You must set the private Docker registry that you'll use to store the images.
As bits are downloaded from Internet, the images are relocated using your
private Docker registry. You don't need access to this registry while you
run this script though.

When the script finishes, the images are stored as TAR files. There's also
a manifest file named `tkg-images.txt`.

Copy those files to your air-gapped environment.

## Uploading TKG images to your private Docker registry

At this point, you don't need Internet access. All you need is a
Docker daemon running, and network access to your private registry.

Make sure your private registry matches the registry set when you
downloaded images.

Run this script to upload TKG images:

```bash
$ ./tkg-upload-images.sh
```

You're done!

Now, you can start installing TKG by following the documentation.
Don't forget to set `TKG_CUSTOM_IMAGE_REPOSITORY` in `$HOME/.tkg/config_default.yaml`
using the same value you've just used.

In case your private registry is using unsigned certificates, you also need to set
`TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY` to `true`.

Your TKG configuration file should then look like this:

```yaml
#! Custom image repository settings
#! ---------------------------------------------------------------------
TKG_CUSTOM_IMAGE_REPOSITORY: "harbor.tanzu.local"
TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY: "true"
```
