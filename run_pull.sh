#!/bin/bash
docker pull jcsda/docker-gnu-openmpi-dev:1.9
CONTAINER_ID=$(docker run -d --rm -v "$PWD":/__w/CDEPS/CDEPS -w /__w/CDEPS/CDEPS jcsda/docker-gnu-openmpi-dev:1.9 sleep infinity)
echo "$CONTAINER_ID" > container_id.txt
