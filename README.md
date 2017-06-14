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

### 2. Build the container with the name "friendlyhello"


```
docker build -t friendlyhello .
```

### Run the container friendlyhello
export it to the port "4000" with the "-p" flag
```
docker run -p 4000:80 friendlyhello
```

Check the container in your browser http://localhost:4000

Hit CTRL+C in your terminal to quit.

* Or use the curl command to do it

```
curl http://localhost:4000
```

### Run the app in the background, in detached mode with the ""-d" flag

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

create a docker-compose file
```
touch docker-compose.yml
```
paste the bellow code into the docker-compose.yml

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

### Run your new load-balanced app

You can name the Compose file anything you want to make it logically meaningful to you; "docker-compose.yml" is simply a standard name. We could just as easily have called this file "docker-stack.yml" or something more specific to our project.

```
docker swarm init
```

run it with a name, give your app a name. Here, it is set to getstartedlab.

```
docker stack deploy -c docker-compose.yml getstartedlab

```

See a list of the five containers you just launched with the name :

```
docker stack ps getstartedlab
```
check all container

```
docker stack ps
```

Check one-node swarm is still up and running and it is the leader "swarm'

```
docker node ls
```


## Deployment

You can run curl http://localhost several times in a row, or go to that URL in your browser and hit refresh a few times , or open it on your browser and refresh the webpage several times to see the containers changes based on balance.

The containers will be in load balance now.

### Take the app down, and remove the containers

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


## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc
