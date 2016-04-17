# syncthing-discosrv
Docker Container for the global discovery server for the [http://syncthing.net/](http://syncthing.net/) project. I build the container because the official on is virtually dead (last build at the time of writing "a year ago"). This build is listening on the gihub project of the discovery server and gets updated whenever there is a code change. [dicosrv GitHub repo](https://github.com/syncthing/discosrv). The container is intendet for people who like to roll their own private syncthing "cloud".

The files for this container can be found at my [GitHub repo](https://github.com/t4skforce/syncthing-discovery)

[![](https://badge.imagelayers.io/t4skforce/syncthing-discovery:latest.svg)](https://imagelayers.io/?images=t4skforce/syncthing-discovery:latest 'Get your own badge on imagelayers.io')

# About the Container

This build is based on [ubuntu:latest](https://hub.docker.com/_/ubuntu/) and installs the latests successful build of the syncthing discovery server.

# How to use this image
`docker run --name syncthing-discovery -d -p 22026:22026 --restart=always t4skforce/syncthing-discovery:latest`
This will store the certificates and all of the data in `/home/discosrv/`. You will probably want to make at least the certificate folder a persistent volume (recommended):

`docker run --name syncthing-discovery -d -p 22026:22026 -v /your/home:/home/discosrv/certs --restart=always t4skforce/syncthing-discovery:latest`

If you already have certificates generated and want to use them and protect the folder from being changed by the docker images use the following command:

`docker run --name syncthing-discovery -d -p 22026:22026 -v /your/home:/home/discosrv/certs:ro --restart=always t4skforce/syncthing-discovery:latest`

Creating cert directory and setting permissions (docker process is required to have access):
```bash
mkdir -p /your/home/certs
chown -R 999:docker /your/home/certs
```

# Upgrade
```bash
# download updates
docker pull t4skforce/syncthing-discovery:latest
# stop current running image
docker stop syncthing-discovery
# remove container
docker rm syncthing-discovery
# start with new base image
docker run --name syncthing-discovery -d -p 22026:22026 -v /your/home:/home/discosrv/certs:ro --restart=always t4skforce/syncthing-discovery:latest
```

# Autostart
To enable the discovery server to start at system-startup we need to create a systemd service file `vim /lib/systemd/system/syncthing-discovery.service`:

```ini
[Unit]
Description=Syncthing-Discovery-Server
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a syncthing-discovery
ExecStop=/usr/bin/docker stop -t 2 syncthing-discovery

[Install]
WantedBy=multi-user.target
```

To start the service manually call `systemctl start syncthing-discovery`. For retreaving the current service status call `systemctl status syncthing-discovery`

```bash
root@syncthing:~# systemctl status syncthing-discovery
● syncthing-discovery.service - Syncthing-Discovery-Server
   Loaded: loaded (/lib/systemd/system/syncthing-discovery.service; disabled)
   Active: active (running) since Sun 2016-04-17 14:33:07 BST; 13s ago
 Main PID: 11010 (docker)
   CGroup: /system.slice/syncthing-discovery.service
           └─11010 /usr/bin/docker start -a syncthing-discovery

Apr 17 14:33:07 syncthing docker[11010]: Server device ID is <your device ID of the server>
```

And last but not least we need to enable our newly created service via issuing `systemctl enable syncthing-discovery`:
```bash
root@syncthing:~# systemctl enable syncthing-discovery
Created symlink from /etc/systemd/system/multi-user.target.wants/syncthing-discovery.service to /lib/systemd/system/syncthing-discovery.service.
```

# Auto Upgrade
Combine all the above and autoupgrade the container at defined times. This requires you to at least setup [Autostart](#autostart).

First we need to generate your upgrade shell script `vim /root/syncthing-discovery_upgrade.sh`:

```bash
#!/bin/bash

# Directory to look for the Certificates
CERT_HOME="/your/home/certs"

# download updates
docker pull t4skforce/syncthing-discovery:latest
# stop current running image
docker stop syncthing-discovery
# remove container
docker rm syncthing-discovery
# start with new base image
docker run --name syncthing-discovery -d -p 22026:22026 -v ${CERT_HOME}:/home/discosrv/certs:ro --restart=always t4skforce/syncthing-discovery:latest
# stop container
docker stop syncthing-discovery
# start via service
systemctl start syncthing-discovery
```

Next we need to make this file executable `chmod +x /root/syncthing-discovery_upgrade.sh`, and test if the upgrade script works by calling the shell-script and checking the service status afterwards:
```bash
root@syncthing:~# /root/syncthing-discovery_upgrade.sh
root@syncthing:~# systemctl status syncthing-discovery
● syncthing-discovery.service - Syncthing-Discovery-Server
   Loaded: loaded (/lib/systemd/system/syncthing-discovery.service; enabled)
   Active: active (running) since Sun 2016-04-17 11:42:57 BST; 2s ago
 Main PID: 2642 (docker)
   CGroup: /system.slice/syncthing-discovery.service
           └─2642 /usr/bin/docker start -a syncthing-discovery
```

Now we need to set the trigger for the upgrade. In this example we just setup a weekly upgrade via crontab scheduled for Sunday at midnight. We add `0 0 * * 7 root /root/syncthing-discovery_upgrade.sh` to `/etc/crontab`. The resulting file looks like:

```bash
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user  command
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
# Syncthing-Discovery-Server Docker Container Upgrade
0  0    * * 7   root    /root/syncthing-discovery_upgrade.sh
#
```
