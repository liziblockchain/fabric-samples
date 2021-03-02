#!/bin/bash

# if [ "$1" == "up"]; then
#    ./monitordocker.sh net_test
# elif [ "$1" == "down"]; then
#   docker stop logspout
#   docker rm logspout
# fi

if [ "$1" == "up" ]; then
  ./monitordocker.sh net_test
elif [ "$1" == "down" ]; then
  docker stop logspout
  docker rm logspout
  ./network.sh down
else
  echo "error params"
fi
