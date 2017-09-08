#!/bin/bash
set -xe
git lfs install
git lfs pull
./update-dockerfile.sh
docker-compose build
docker-compose push
kontena stack upgrade --deploy wordpress kontena.yml
