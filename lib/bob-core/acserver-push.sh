#!/usr/bin/env bash

function main() {
    local image_id image_path image_name manifest_name manifest_path registry_host completed_url upload_id
    image_id="$1"
    image_path="$2"
    image_name=$(basename "${image_path}")
    manifest_name="${image_name/.aci/.manifest}"
    manifest_path="$(dirname "${image_path}")${manifest_name}"
    registry_host="localhost"

    completed_url=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "\{\"image\":"${image_id}"\}" "${registry_host}/${image_id}/startupload" | jq -r '.completed_url')
    upload_id="${completed_url#*/complete/}"

    echo "uploading ${image_name}"
    curl "${registry_host}/aci/${upload_id}" --upload-file "${image_path}"
    echo "uploading ${manifest_name}"
    curl "${registry_host}/manifest/${upload_id}" --upload-file "${manifest_name}"
    echo "finish upload"
    curl -X POST -H "Content-Type: application/json" -d '{"success":true}' "${registry_host}/complete/${upload_id}"
}

main "$@"
