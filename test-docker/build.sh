#!/usr/bin/env bash 
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( dirname "$SCRIPT_DIR" )"
cd "$PARENT_DIR"
docker build . -f test-docker/Dockerfile -t homebrew-acl2s-test --progress=plain
