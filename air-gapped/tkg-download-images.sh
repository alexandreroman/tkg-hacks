#!/usr/bin/env bash
# Original work Copyright 2020 The TKG Contributors.
# Modified work Copyright 2021 VMware, Inc. or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

TANZU_BOM_DIR=${HOME}/.tanzu/tkg/bom
LEGACY_BOM_DIR=${HOME}/.tkg/bom
INSTALL_INSTRUCTIONS='See https://github.com/mikefarah/yq#install for installation instructions'

usage() { echo "Usage: $0 -o <output dir> -k <kubernetes version> -i <additional image>" 1>&2; exit 1; }

outputDir=$PWD
kubernetesVersions=""
additionalImages=""
while getopts "o:k:i:" opt; do
    case "${opt}" in
        o)
            outputDir=${OPTARG}
            ;;
        k)
            kubernetesVersions="${OPTARG} ${kubernetesVersions}"
            ;;
        i)
            additionalImages="${OPTARG} ${additionalImages}"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -d "$TANZU_BOM_DIR" ]]; then
  BOM_DIR="${TANZU_BOM_DIR}"
elif [[ -d "$LEGACY_BOM_DIR" ]]; then
  BOM_DIR="${LEGACY_BOM_DIR}"
else
  echo "Tanzu Kubernetes Grid directories not found. Run CLI once to initialise." >&2
  exit 2
fi

if ! [ -x "$(command -v imgpkg)" ]; then
  echo 'Error: imgpkg is not installed.' >&2
  exit 3
fi

if ! [ -x "$(command -v yq)" ]; then
  echo 'Error: yq is not installed.' >&2
  echo "${INSTALL_INSTRUCTIONS}" >&2
  exit 3
fi

mkdir -p "${outputDir}"
manifestFile=${outputDir}/manifest.yml
if ! [ -f "${manifestFile}" ]; then
  cat > "${manifestFile}" << EOF
images:
EOF
fi

if [ -z "${kubernetesVersions}" ]; then
    echo "No Kubernetes version set: run 'imgpkg tag list -i projects.registry.vmware.com/tkg/tkr-bom' to list available Kubernetes versions." >&2
    usage
fi

actualImageRepository=""
for TKG_BOM_FILE in "$BOM_DIR"/tkg-bom-*.yaml; do
  echo "Processing BOM file ${TKG_BOM_FILE}"
  actualImageRepository=$(yq e '.imageConfig.imageRepository' "$TKG_BOM_FILE")
  yq e '.. | select(has("images"))|.images[] | .imagePath + ":" + .tag ' "$TKG_BOM_FILE" |
    while read -r image; do
      actualImage=${actualImageRepository}/${image}
      tarImage="$(echo $actualImage | md5sum | awk '{ print $1 }').tar"
      if ! [ -f "${outputDir}/${tarImage}" ]; then
        imgpkg copy --include-non-distributable-layers -i "${actualImage}" --to-tar "${outputDir}/${tarImage}"
        cat >> "${manifestFile}" << EOF
- repo: ${actualImageRepository}
  image: ${image%:*}
  tag: ${image##*:}
  file: ${tarImage}
EOF
      fi
    done
  echo "Finished processing BOM file ${TKG_BOM_FILE}"
done

for imageTag in ${kubernetesVersions}; do
  if [[ ${imageTag} == v* ]]; then
    echo "Processing BOM file for Kubernetes version ${imageTag}"
    tarImage="$(echo ${actualImageRepository}/tkr-bom:${imageTag} | md5sum | awk '{ print $1 }').tar"
    if ! [ -f "${outputDir}/${tarImage}" ]; then
      imgpkg copy --include-non-distributable-layers -i "${actualImageRepository}/tkr-bom:${imageTag}" --to-tar "${outputDir}/${tarImage}"
      cat >> "${manifestFile}" << EOF
- repo: ${actualImageRepository}
  image: tkr-bom
  tag: ${imageTag}
  file: ${tarImage}
EOF
    fi

    imgpkg pull --image ${actualImageRepository}/tkr-bom:${imageTag} --output "tmp" > /dev/null 2>&1
    yq e '.. | select(has("images"))|.images[] | .imagePath + ":" + .tag ' "$(ls tmp/*.yaml)" |
    while read -r image; do
      actualImage=${actualImageRepository}/${image}
      tarImage="$(echo $actualImage | md5sum | awk '{ print $1 }').tar"
      if ! [ -f "${outputDir}/${tarImage}" ]; then
        imgpkg copy --include-non-distributable-layers -i "${actualImage}" --to-tar "${outputDir}/${tarImage}"
        cat >> "${manifestFile}" << EOF
- repo: ${actualImageRepository}
  image: ${image%:*}
  tag: ${imageTag}
  file: ${tarImage}
EOF
      fi
    done
    rm -rf tmp
  fi
  echo "Finished processing BOM file for Kubernetes version ${imageTag}"
done

list=$(imgpkg tag list -i ${actualImageRepository}/tkr-compatibility)
for imageTag in ${list}; do
  if [[ ${imageTag} == v* ]]; then 
    echo "Processing TKR compatibility image ${imageTag}"
    actualImage=${actualImageRepository}/tkr-compatibility:${imageTag}
    tarImage="$(echo $actualImage | md5sum | awk '{ print $1 }').tar"
    if ! [ -f "${outputDir}/${tarImage}" ]; then
      imgpkg copy --include-non-distributable-layers -i "${actualImage}" --to-tar "${outputDir}/${tarImage}"
      cat >> "${manifestFile}" << EOF
- repo: ${actualImageRepository}
  image: tkr-compatibility
  tag: ${imageTag}
  file: ${tarImage}
EOF
    fi
  fi
done

for image in ${additionalImages}; do
  echo "Processing additional image ${image}"
  tarImage="$(echo $image | md5sum | awk '{ print $1 }').tar"
  if ! [ -f "${outputDir}/${tarImage}" ]; then
    imgpkg copy --include-non-distributable-layers -i "${image}" --to-tar "${outputDir}/${tarImage}"
    cat >> "${manifestFile}" << EOF
- repo: index.docker.io
  image: ${image%:*}
  tag: ${image##*:}
  file: ${tarImage}
EOF
  fi
done
