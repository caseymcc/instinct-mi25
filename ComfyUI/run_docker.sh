#!/bin/bash

forceStart=false
rebuild=false
exit_docker=false
while getopts "sre" flag
do
    case "${flag}" in
        s) forceStart=true;;
        r) rebuild=true;;
        e) exit_docker=true;;
    esac
done

DOCKERFILE="Dockerfile"
DOCKER_NAME="comfyui_image"
CONTAINER_NAME="comfyui_local"

if [ "$rebuild" = true ] || [ "$forceStart" = true ] || [ "$exit_docker" = true ]; then

  running=$(docker container inspect -f '{{.State.Running}}' $CONTAINER_NAME 2>/dev/null)
  if [ "$running" == "true" ]; then
    echo "Stopping container"
    result=$(docker stop $CONTAINER_NAME)
  fi

  exists=$(docker ps -aq -f name=$CONTAINER_NAME)
  if [ "$exists" ]; then
    echo "Removing container"
    result=$(docker rm $CONTAINER_NAME)
  fi

  if [ "$exit_docker" = true ]; then
    exit 0
  fi

  if [ "$rebuild" = true ]; then
    result=$(docker images -q $DOCKER_NAME )
    if [[ -n "$result" ]]; then
      "Deleting docker"
      result=$(docker rmi $DOCKER_NAME)
    fi
  fi
fi

result=$(docker images -q $DOCKER_NAME )
if [[ ! -n "$result" ]]; then
  echo "Building docker image"
  DOCKER_BUILDKIT=1 docker build \
    --build-arg RENDER_GROUP_ID=$(getent group render | cut -d: -f3) \
    -t $DOCKER_NAME -f ${DOCKERFILE} .
fi

exists=$(docker ps -aq -f name=$CONTAINER_NAME)
if [ ! "$exists" ]; then
  echo "Creating docker"
  docker create -it --name $CONTAINER_NAME \
    -p 8188:8188 \
    -v "$(pwd)"/storage:/home/runner \
    -v "$(pwd)"/scripts:/home/scripts \
    --env CLI_ARGS="--use-pytorch-cross-attention" \
    --env CUDA_VISIBLE_DEVICES=0 \
    --device=/dev/kfd --device=/dev/dri \
    --security-opt seccomp=unconfined \
    --group-add video \
    --group-add render \
    -v ${PWD}:/home/${USER}/$(basename ${PWD}) \
    $DOCKER_NAME
fi

running=$(docker container inspect -f '{{.State.Running}}' $CONTAINER_NAME 2>/dev/null)
if [ "$running" != "true" ]; then
  echo "Starting docker"
  result=$(docker start $CONTAINER_NAME)
fi

echo "Attaching to docker"
docker exec -it $CONTAINER_NAME bash

