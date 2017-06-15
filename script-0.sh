#!/bin/bash

echo "This script run the CMD automatically for you!"

echo "#####"

echo "Creat two virtual machines with virtual box ..."

echo "$ docker-machine create --driver virtualbox myvm1"
docker-machine create --driver virtualbox myvm1

echo "$ docker-machine create --driver virtualbox myvm2"
docker-machine create --driver virtualbox myvm2

echo "myvm1 is swarm manager"
docker-machine ssh myvm1 "docker swarm init"

echo "------------------------------"

echo " using that IP and specifying port 2377 (the port for swarm joins) with --advertise-addr  "
echo "$ docker-machine ssh myvm1 "docker swarm init --advertise-addr 192.168.99.100:2377"  "
docker-machine ssh myvm1 "docker swarm init --advertise-addr 192.168.99.100:2377"

echo "------------------------------"

echo " Join your new swarm as a worker: make the myvm2 be a worker "
echo "uses: docker swarm join "
echo " "

echo "Run this CMD: (docker-machine ssh myvm2)"
echo "Into myvm2 run the (docker swarm join) cmd given above"
