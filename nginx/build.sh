#!/bin/bash
set -e

cd "$(dirname "$0")"
IMAGE_NAME="aquabase/nginx:${VERSION}-$(uname -r)"
