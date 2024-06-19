# Docker

## List of Images

```bash
docker images
```

## List of Containers

```bash
docker ps

# All containers
docker ps -a
```

## Start/Stop Container

```bash
docker run <image_name>
docker start <container_id>

docker stop <container_id>
```

## Volume

```bash
docker run -v /path/to/host:/path/to/container <image_name>
```

## Environment Variables

```bash
docker run -e <key>=<value> <image_name>
```

## Port Mapping

```bash
docker run -p <host_port>:<container_port> <image_name>
```

## Remove Container

```bash
docker rm <container_id>
```

## Remove Image

```bash
docker rmi <image_id>
```

## Remove All Containers

```bash
docker rm $(docker ps -a -q)
```

## Remove All Images

```bash
docker rmi $(docker images -q)
```

## Stop All Containers

```bash
docker stop $(docker ps -a -q)
```

## Remove All Containers and Images

```bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
```

## Pruining

```bash
docker system prune
```

## Remove All Unused Images

```bash
docker image prune
```

## Compose

```bash
docker compose up

docker compose up -d

docker compose down
```
