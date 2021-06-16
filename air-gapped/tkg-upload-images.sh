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

INSTALL_INSTRUCTIONS='See https://github.com/mikefarah/yq#install for installation instructions'

usage() { echo "Usage: $0 -r <repository> -i <input dir>" 1>&2; exit 1; }

inputDir=$PWD
repo=""
while getopts "r:i:" opt; do
    case "${opt}" in
        r)
            repo=${OPTARG}
            ;;
        i)
            inputDir=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${repo}" ]; then
    usage
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

manifestFile=$inputDir/manifest.yml
if [ ! -f "$manifestFile" ]; then
    echo "Missing TKG images manifest: $manifestFile" >&2
    exit 1
fi

yq e '.. | select(has("images"))|.images[] | .file + "=" + .image' "$manifestFile" |
    while read -r entry; do
      tar=${entry%=*}
      image=${entry##*=}
      echo "Uploading image ${image}"
      imgpkg copy --tar "${inputDir}/${tar}" --to-repo "${repo}/${image}"
    done
