# Rocket.Chat docker image for 64bit ARM servers

You can edit the following line in `docker-compose.yml` file to change the version of Rocket.Chat the image will contain:

```
ENV RC_VERSION x.x.x
```

To build this image and publish to your local registry, use the command:

```
docker build -t rc .
```
