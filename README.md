### Useful docker commands
```
docker build -t friendlyname .  # Create image using this directory's Dockerfile
docker run -p 4000:80 friendlyname  # Run "friendlyname" mapping port 4000 to 80
docker run -d -p 4000:80 friendlyname         # Same thing, but in detached mode
docker ps                                 # See a list of all running containers
docker stop <hash>                     # Gracefully stop the specified container
docker ps -a           # See a list of all containers, even the ones not running
docker kill <hash>                   # Force shutdown of the specified container
docker rm <hash>              # Remove the specified container from this machine
docker rm $(docker ps -a -q)           # Remove all containers from this machine
docker images -a                               # Show all images on this machine
docker rmi <imagename>            # Remove the specified image from this machine
docker rmi $(docker images -q)             # Remove all images from this machine
docker login             # Log in this CLI session using your Docker credentials
docker tag <image> username/repository:tag  # Tag <image> for upload to registry
docker push username/repository:tag            # Upload tagged image to registry
docker run username/repository:tag                   # Run image from a registry
```

### Intro

The source of information is from https://docs.docker.com/

1. Get set up and oriented, on this page.
2. Build and run your first app
3. Turn your app into a scaling service
4. Span your service across multiple machines
5. Add a visitor counter that persists data
6. Deploy your swarm to production

### 1. Installing

A step by step series of "docker" (I have use MAC for this repo).

install docker  https://store.docker.com/editions/community/docker-ce-desktop-mac

Check if the last stable version is installed

```
docker --version
```

My version is ( Docker version 17.03.1-ce, build c6d412e )

## Build and run your the first container

Create an empty directory named "docker-intro" and put this file in it, with the name Dockerfile, paste the bellow code into Dockerfile.

```
# Use an official Python runtime as a base image
FROM python:2.7-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Install any needed packages specified in requirements.txt
RUN pip install -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]

```

Create two more files

```
touch app.py requirements.txt
```

Paste this inside the requirements.txt file

```
Flask
Redis
```

And this inside the app.py file

```
from flask import Flask
from redis import Redis, RedisError
import os
import socket

# Connect to Redis
redis = Redis(host="redis", db=0, socket_connect_timeout=2, socket_timeout=2)

app = Flask(__name__)

@app.route("/")
def hello():
    try:
        visits = redis.incr("counter")
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    html = "<h3>Hello {name}!</h3>" \
           "<b>Hostname:</b> {hostname}<br/>" \
           "<b>Visits:</b> {visits}"
    return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname(), visits=visits)

if __name__ == "__main__":
	app.run(host='0.0.0.0', port=80)
```

### 2. Build the container with the name "friendlyhello".


```
docker build -t friendlyhello .
```

#### Run the container "friendlyhello"
Export it to the port "4000" with the "-p" flag, running in attached mode

```
docker run -p 4000:80 friendlyhello
```

Check the container in your browser http://localhost:4000


Using the keyboard to stop the container running in the attached mode:


Hit ```CTRL+C``` in your terminal to quit.

* Or use the curl command to do it

```
curl http://localhost:4000
```

#### Run the app in the background, in detached mode with the ""-d" flag.

```
docker run -d -p 4000:80 friendlyhello
```

Get the containerID
```
docker ps
```

Stop the container running in the detached mode "docker stop containerID"
```
docker stop 262decdc73ec
```

### 3. Scale our application and enable load-balancing with docker-compose.yml file.

Create a docker-compose file

```
touch docker-compose.yml
```
Paste the bellow code into the docker-compose.yml

```
version: "3"
services:
  web:
    # replace username/repo:tag with your name and image details
    # Pull the image we uploaded in step 2 from the registry.
    image: username/repository:tag
    deploy:
    # Run five instances of that image as a service called web
      replicas: 5
      resources:
        limits:
        # limiting each one to use, at most, 10% of the CPU (across all cores), and 50MB of RAM.
          cpus: "0.1"
          memory: 50M
      restart_policy:
      # Immediately restart containers if one fails.
        condition: on-failure
    ports:
    # Map port 80 on the host to web’s port 80.
      - "80:80"
    networks:
    # Instruct web’s containers to share port 80 via a load-balanced network called webnet
      - webnet
networks:
# Define the webnet network with the default settings (which is a load-balanced overlay network).
  webnet:
```

#### Run your new load-balanced app

You can name the Compose file anything you want to make it logically meaningful to you; "docker-compose.yml" is simply a standard name. We could just as easily have called this file "docker-stack.yml" or something more specific to our project.

```
docker swarm init
```

Run it with a name, give your app a name. Here, it is set to getstartedlab.

```
docker stack deploy -c docker-compose.yml getstartedlab

```

See a list of the five containers you just launched with the name :

```
docker stack ps getstartedlab
```
Check all container

```
docker stack ps
```

Check one-node swarm is still up and running and it is the leader "swarm'

```
docker node ls
```

#### Deployment

You can run curl http://localhost several times in a row, or go to that URL in your browser and hit refresh a few times , or open it on your browser and refresh the webpage several times to see the containers changes based on balance.

The containers will be in load balance now.

#### Take the app down, and remove the containers

Take the app down with docker stack rm

```
docker stack rm getstartedlab
```

This removes the app, but our one-node swarm is still up and running (as shown by docker node ls). Take down the swarm with

```
docker swarm leave --force.
```

Some commands to explore at this stage:

```
docker stack ls              # List all running applications on this Docker host
docker stack deploy -c <composefile> <appname>  # Run the specified Compose file
docker stack services <appname>       # List the services associated with an app
docker stack ps <appname>   # List the running containers associated with an app
docker stack rm <appname>                             # Tear down an application
```

Commands you might like to run to interact with your swarm a bit

```
docker-machine create --driver virtualbox myvm1 # Create a VM (Mac, Win7, Linux)
docker-machine create -d hyperv --hyperv-virtual-switch "myswitch" myvm1 # Win10
docker-machine env myvm1                # View basic information about your node
docker-machine ssh myvm1 "docker node ls"         # List the nodes in your swarm
docker-machine ssh myvm1 "docker node inspect <node ID>"        # Inspect a node
docker-machine ssh myvm1 "docker swarm join-token -q worker"   # View join token
docker-machine ssh myvm1   # Open an SSH session with the VM; type "exit" to end
docker-machine ssh myvm2 "docker swarm leave"  # Make the worker leave the swarm
docker-machine ssh myvm1 "docker swarm leave -f" # Make master leave, kill swarm
docker-machine start myvm1            # Start a VM that is currently not running
docker-machine stop $(docker-machine ls -q)               # Stop all running VMs
docker-machine rm $(docker-machine ls -q) # Delete all VMs and their disk images
docker-machine scp docker-compose.yml myvm1:~     # Copy file to node's home dir
docker-machine ssh myvm1 "docker stack deploy -c <file> <app>"   # Deploy an app
```

### 4. Swarm clusters
A swarm is a group of machines that are running Docker and joined into a cluster

create at least 2 vms

```
docker-machine create --driver virtualbox myvm1
docker-machine create --driver virtualbox myvm2
```

Make swarm manager with

```
docker-machine ssh myvm1 "docker swarm init"
```

The port for swarm joins with "--advertise-addr"

```
docker-machine ssh myvm1 "docker swarm init --advertise-addr 192.168.99.100:2377"

```

One node will be the manager (leader) the the other the worker (node worker)

```
docker-machine ssh myvm2 "docker swarm join \
--token <token> \
<ip>:<port>"

This node joined a swarm as a worker.
```
Check the vms (leader and worker)
if the node has nothing on the column "MANAGER STATUS" it's worker

```
docker-machine ssh myvm1 "docker node ls"
```

Copy the "docker-compose.yml" file from the local machin into the learder vm with the 'scp' protocol

```
docker-machine scp docker-compose.yml myvm1:~
```

The vm myvm1 use its powers as a swarm manager to deploy your app

```
docker-machine ssh myvm1 "docker stack deploy -c docker-compose.yml getstartedlab"

```

Check the deployment by ssh into vm "myvm1" leader

```
docker-machine ssh myvm1
```

Inside the myvm1 type

```
"docker stack ps getstartedlab"
```

 Or simply do

 ```
 docker-machine ssh myvm1 "docker stack ps getstartedlab"
 ```

 You can tear down the stack with docker stack rm.

```
 docker-machine ssh myvm1 "docker stack rm getstartedlab"
```

You can remove this swarm if you want to with ```docker-machine ssh myvm2 "docker swarm leave"``` on the worker and ```docker-machine ssh myvm1 "docker swarm leave --force"``` on the manager


### 5. Swarm clusters with visualizer

```
version: "3"
services:
  web:
    # replace username/repo:tag with your name and image details
    image: username/repo:tag
    deploy:
      replicas: 5
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
    ports:
      - "80:80"
    networks:
      - webnet
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
networks:
  webnet:
```

Copy this new docker-compose.yml file to the swarm manager, myvm1

```
docker-machine scp docker-compose.yml myvm1:~

```

Re-run the docker stack deploy command on the manager

```
docker-machine ssh myvm1 "docker stack deploy -c docker-compose.yml getstartedlab"

```

Check from the visualizer on ```http://192.168.99.100:8080/```

Check from the CMD ```docker-machine ssh myvm1 "docker stack ps getstartedlab"```

If you stop the containers the date will be lost fro that reason let's do the same but the "Persist the data" now

New "docker-compose.yml" file

```
version: "3"
services:
  web:
    # replace username/repo:tag with your name and image details
    image: username/repo:tag
    deploy:
      replicas: 5
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
    ports:
      - "80:80"
    networks:
      - webnet
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
  redis:
    image: redis
    ports:
      - "6379:6379"
    volumes:
      - ./data:/data
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
networks:
  webnet:
```

Ready to deploy your new Redis-using stack
Create a ./data directory on the manager:
Redis service that will provide a visitor counter.

```
docker-machine ssh myvm1 "mkdir ./data"
```

Replace the docker-compose.yml file
```
docker-machine scp docker-compose.yml myvm1:~
```

Run docker stack deploy one more time.

```
docker-machine ssh myvm1 "docker stack deploy -c docker-compose.yml getstartedlab"
```

=======================================
Check the app on browser ```http://192.168.99.100``` or ```http://192.168.99.101```

Check the app with curl ```curl http://192.168.99.100``` or ``` curl http://192.168.99.101 ```

Check from the visualizer on ```http://192.168.99.100:8080/```

Check from the CMD ```docker-machine ssh myvm1 "docker stack ps getstartedlab"```


### References and Authors
https://docs.docker.com/
