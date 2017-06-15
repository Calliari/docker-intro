#!/bin/bash

echo "remove all stack replicas from myvm1"
docker-machine ssh myvm1 "docker stack rm getstartedlab"

echo "remove worker from swarm"

echo "docker swarm leave --> on the worker"
docker-machine ssh myvm2 "docker swarm leave"

echo "docker swarm leave --> on the manager "
docker-machine ssh myvm1 "docker swarm leave --force"

echo "docker-machine stop myvm1 && myvm2"
docker-machine stop myvm1 myvm2

echo "remove vm myvm2 && myvm1"
docker-machine rm -y myvm2 myvm1
