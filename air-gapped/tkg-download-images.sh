#!/usr/bin/env bash
# Original work Copyright 2020 The TKG Contributors.
# Modified work Copyright 2020 VMware, Inc. or its affiliates.
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

usage() { echo "Usage: $0 -r <repository> -o <output dir>" 1>&2; exit 1; }

outputDir=$PWD
while getopts "r:o:" opt; do
    case "${opt}" in
        r)
            repo=${OPTARG}
            ;;
        o)
            outputDir=${OPTARG}
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

BOM_DIR=${HOME}/.tkg/bom
if [ ! -d $BOM_DIR ]; then
    echo "Cannot locate TKG directory: did you run 'tkg get mc'?"
    exit 1
fi

imagesFile=$outputDir/tkg-images.txt
rm -f "$imagesFile"

declare -a additionalImages=(
    "metallb/speaker:v0.9.5"
    "metallb/controller:v0.9.5"
)

for actualImage in "${additionalImages[@]}"; do
    customImage=$repo/$actualImage

    docker pull $actualImage && \
    docker tag  $actualImage $customImage
    imageRawId=$(docker inspect --format='{{index .Id}}' $customImage)
    imageId=${imageRawId:7}
    docker save -o "$outputDir/$imageId.tar" $customImage

    echo $customImage >> $imagesFile
done

for TKG_BOM_FILE in "$BOM_DIR"/*.yaml; do
    # Get actual image repository from BoM file
    actualImageRepository=$(yq r "$TKG_BOM_FILE" imageConfig.imageRepository | tr -d '"')

    # Iterate through BoM file to create the complete Image name
    # and then pull, retag and save image to disk
    yq r --tojson "$TKG_BOM_FILE" images | jq -c '.[]' | while read -r i; do
        # Get imagePath and imageTag
        imagePath=$(jq .imagePath <<<"$i" | tr -d '"')
        imageTag=$(jq .tag <<<"$i" | tr -d '"')

        # create complete image names
        actualImage=$actualImageRepository/$imagePath:$imageTag
        customImage=$repo/$imagePath:$imageTag

        docker pull $actualImage && \
        docker tag  $actualImage $customImage

        imageRawId=$(docker inspect --format='{{.ID}}' $customImage)
        imageId=${imageRawId:7}
        docker save -o "$outputDir/$imageId.tar" $customImage

        echo $customImage >> $imagesFile
    done
done
