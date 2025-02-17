#!/bin/bash

set -e

NAUTES_PATH="/opt/nautes"
NAUTES_LOG_PATH="${NAUTES_PATH}/out/logs"

REPO_URL="https://github.com/nautes-labs/tenant-repo-template.git"
TARGET_DIR="${NAUTES_PATH}/management"

CONTAINER_NAME=nautes-installer
INSTALLER_VERSION=v0.2.0

if [ -d "$TARGET_DIR/.git" ]; then
    echo "Repository already exists, updating to the latest code..."
    git --git-dir="$TARGET_DIR/.git" --work-tree="$TARGET_DIR" fetch
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch updates from the remote repository."
        exit 1
    fi
    git --git-dir="$TARGET_DIR/.git" --work-tree="$TARGET_DIR" merge origin/HEAD
    if [ $? -ne 0 ]; then
        echo "Error: Failed to merge updates from the remote repository."
        exit 1
    fi
else
    echo "Repository not found, cloning to the /opt/ directory..."
    git clone "$REPO_URL" "$TARGET_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone the repository."
        exit 1
    fi
fi

if ! [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
	docker run -d --name $CONTAINER_NAME \
    -v $NAUTES_PATH/out:/opt/out \
    -v $NAUTES_PATH/terraform:/tmp/terraform \
    -v $NAUTES_PATH/management:/opt/management \
    -v `pwd`/vars.yaml:/opt/vars.yaml \
    ghcr.io/nautes-labs/installer:${INSTALLER_VERSION} \
      tail -f /dev/null
fi

mkdir -p ${NAUTES_LOG_PATH}

docker exec -it $CONTAINER_NAME install-all | tee ${NAUTES_LOG_PATH}/install.log

