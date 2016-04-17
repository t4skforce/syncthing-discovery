# syncthing-discosrv
Docker Container for the global discovery server for the [http://syncthing.net/](http://syncthing.net/) project. I build the container because the official on is virtually dead (last build at the time of writing "a year ago"). This build is listening on the gihub project of the discovery server and gets updated whenever there is a code change. [dicosrv GitHub repo](https://github.com/syncthing/discosrv). The container is intendet for people who like to roll their own private syncthing "cloud".

The files for this container can be found at my [GitHub repo](https://github.com/t4skforce/syncthing-discovery)

# About the Container

This build is based on [ubuntu:latest](https://hub.docker.com/_/ubuntu/) and installs the latests successful build of the syncthing discovery server.

# How to use this image
`docker run --name syncthing-discovery -d -p 22026:22026 t4skforce/syncthing-discovery:latest`
This will store the certificates and all of the data in `/home/discosrv/`. You will probably want to make at least the certificate folder a persistent volume (recommended):

`docker run --name syncthing-discovery -d -p 22026:22026 -v /your/home:/home/discosrv/certs t4skforce/syncthing-discovery:latest`

If you already have certificates generated and want to use them and protect the folder from being changed by the docker images use the following command:

`docker run --name syncthing-discovery -d -p 22026:22026 -v /your/home:/home/discosrv/certs:ro t4skforce/syncthing-discovery:latest`

