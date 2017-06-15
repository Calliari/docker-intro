#!/bin/bash

echo -e "---- Check for virtual machines"
docker-machine ls

echo -e "\n ---- Check for leader and worker nodes, view the nodes in this swarm "
docker-machine ssh myvm1 "docker node ls"

echo -e "\n ---- Check for tasks running on one or more nodes, defaults to current node "
docker-machine ssh myvm1 "docker node ps"

echo -e "\n ---- List the tasks in the stack "
docker-machine ssh myvm1 "docker stack ps getstartedlab"
