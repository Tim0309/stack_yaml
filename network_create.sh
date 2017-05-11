#!/bin/bash

network_NAME='gb-net'

docker network create \
    --attachable \
    -d overlay \
    --subnet=10.10.0.0/16 \
    ${network_NAME}

