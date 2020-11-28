#!/usr/bin/env bash
# Copyright 2020 VMware, Inc. or its affiliates.
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

usage() { echo "Usage: $0 -i <input dir>" 1>&2; exit 1; }

inputDir=$PWD
while getopts "i:" opt; do
    case "${opt}" in
        i)
            inputDir=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

imagesFile=$inputDir/tkg-images.txt
if [ ! -f "$imagesFile" ]; then
    echo "Missing TKG images manifest: $imagesFile"
    exit 1
fi

for imageFile in $inputDir/*.tar; do
    docker load -i "$imageFile" || exit 1
done

while IFS= read -r line
do
    customImage="$line"
    docker push $customImage || exit 1
done < "$imagesFile"
