#!/bin/bash

echo "$ docker-machine ssh myvm1 "mkdir ./data" "
docker-machine ssh myvm1 "mkdir ./data"
echo "Directory created successiful!"

echo "$ docker-machine scp docker-compose-WITH-visualiser-redis.yml myvm1:~"
docker-machine scp docker-compose-WITH-visualiser-redis.yml myvm1:~
echo "Visualiser and Redis successiful installed in the myvm1!"


echo "$ docker-machine ssh myvm1 "docker stack deploy -c docker-compose-WITH-visualiser-redis.yml getstartedlab" "
docker-machine ssh myvm1 "docker stack deploy -c docker-compose-WITH-visualiser-redis.yml getstartedlab"
echo " Running deploy command...  "
