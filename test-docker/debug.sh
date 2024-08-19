#!/usr/bin/env bash 
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( dirname "$SCRIPT_DIR" )"
cd "$PARENT_DIR"

# This script uses fancy experimental Docker BuildKit features to
# provide a nice debug experience
export BUILDX_EXPERIMENTAL=1
docker buildx debug --invoke /bin/bash --on=error build . -f test-docker/Dockerfile -t homebrew-acl2s-test --progress=plain
