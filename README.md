# f0rkznet ArkNet

Arknet configuration and deployment repository.

# Prerequisites

Linux system with docker installed

# Usage

Clone the repository and initalize the configuration:

```bash
git clone git@github.com:f0rkznet/arknet.git
cd arknet
cp docker-compose.yml.example docker-compose.yml
cp .env.example .env
```

# Docker Compose

Customize your server.

Edit the docker-compose.yml file to your specifications.

An example of a multi server cluster is below:

```yaml
services:
  check_updates:
    image: arknet-update-check
    build:
      context: .
      dockerfile: Dockerfile.update-check
    volumes:
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock
  coolserver:
    image: arknet
    build:
      context: .
      dockerfile: Dockerfile
    env_file: .env
    environment:
      - clusterid=my-cluster-id
      - AltSaveDirectoryName=island
      - SERVER_MAP=TheIsland_WP
      - SessionName="Cool Server"
      - QueryPort=27015
      - Port=7777
      - RCONPort=27020
    ports:
      - 0.0.0.0:7777:7777/udp
      - 0.0.0.0:7778:7778/udp
      - 0.0.0.0:27020:27020/tcp
      - 0.0.0.0:27015:27015/udp
    volumes:
      - ./data:/data
    privileged: true
  coolerserver:
    image: arknet
    build:
      context: .
      dockerfile: Dockerfile
    env_file: .env
    environment:
      - clusterid=my-cluster-id
      - AltSaveDirectoryName=scorchedearth
      - SERVER_MAP=ScorchedEarth_P
      - SessionName="Cooler Server"
      - QueryPort=27016
      - Port=7779
      - RCONPort=27021
    ports:
      - 0.0.0.0:7779:7779/udp
      - 0.0.0.0:7780:7780/udp
      - 0.0.0.0:27021:27021/tcp
      - 0.0.0.0:27016:27016/udp
    volumes:
      - ./data:/data
    privileged: true
```

# Configure

Customize your environment:

Edit the .env file included with this project.

Each ark option in the Game.ini and GameUserSettings.ini that you would need to change is defined there. Once the environment is loaded, it renders templates in the `templates/` directory. This allows easy extension of new parameters and extensions to the ini files.

To add a new param, simply edit the responsible template and add the new parameter as so:

```
allowThirdPersonPlayer={{ .allowThirdPersonPlayer }}
```

And in the .env file:

```
allowThirdPersonPlayer=1
```

# Build your environment

Now you're ready to build the containers:

```
# Inside the arknet project folder...
docker compose build
```

Once you are done building, launch it!

```
docker compose up -d
```

Check the server logs:

```
docker compose logs -f
```

You can safely hit control+c from this dialoug.

Congratulations! You have made an ark server.

# Shutting down the server

There is a delay to shut down the container to give a warning to your players (IE: They're in the sky). This will do its best to try and warn your players and wait an ample amount of time.

Docker compose should be given a longer timeout to accomidate this:

```
docker compose stop --timeout=300
```

# Ark Updates

An update daemon has been included to watch for changes. It will restart the server cluster when it detects version changes. If you do not wish to have this feature, simply remove it from the docker-compose.yml file.

Note, this does a very sweeping docker restart command. Use with caution on shared systems! A dedicated ark VM is important when using this script.

# Networking

You need to forward ports:
 - 7777/udp
 - 7778/udp
 - 27015/udp

The rcon port should not be forwarded to the internet unless you intend to remotely configure your server.