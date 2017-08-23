#!/bin/bash -ex

prep() {
    yum -y update
    yum -y install docker git
    systemctl start docker
}

build_image() {
    make docker-build
}

tag_push() {
  local target=$1
  local source=$2
  docker tag ${source} ${target}
  docker push ${target}
}

push_image() {
    local image_name
    local image_repository
    local tag
    local push_registry
    image_name=$(make get-image-name)
    image_repository=$(make get-image-repository)
    tag=$(git rev-parse --short=7 HEAD)
    push_registry="push.registry.devshift.net"

    # login first
    if [ -n "${DEVSHIFT_USERNAME}" -a -n "${DEVSHIFT_PASSWORD}" ]; then
        docker login -u ${DEVSHIFT_USERNAME} -p ${DEVSHIFT_PASSWORD} ${push_registry}
    else
        echo "Could not login, missing credentials for the registry"
        exit 1
    fi

    tag_push ${push_registry}/${image_repository}:latest ${image_name}
    tag_push ${push_registry}/${image_repository}:${tag} ${image_name}
    echo 'CICO: Image pushed, ready to update deployed app'
}

prep
