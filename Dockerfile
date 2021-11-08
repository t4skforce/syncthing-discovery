FROM debian:latest
########################################
#              Settings                #
########################################
# Syncthing-Discovery Server

ENV SERV_PORT       22026
ENV DISCO_OPTS      ""

########################################
#               Setup                  #
########################################
ENV USERNAME discosrv
ENV USERGROUP discosrv
ENV APPUID 1000
ENV APPGID 1000
ENV USER_HOME /home/discosrv
ENV BUILD_REQUIREMENTS curl openssl
ENV REQUIREMENTS ca-certificates
########################################

########################################
#               Build                  #
########################################
ARG VERSION="v1.18.1"
ARG DOWNLOADURL="https://github.com/syncthing/discosrv/releases/download/v1.18.1/stdiscosrv-linux-amd64-v1.18.1.tar.gz"
ARG BUILD_DATE="2021-11-08T13:18:07Z"
########################################

USER root
ENV DEBIAN_FRONTEND noninteractive
# setup
RUN apt-get update -qqy \
	&& apt-get -qqy --no-install-recommends install ${BUILD_REQUIREMENTS} ${REQUIREMENTS} \
	&& mkdir -p ${USER_HOME} \
	&& groupadd --system --gid ${APPGID} ${USERGROUP} \
	&& useradd --system --uid ${APPUID} -g ${USERGROUP} ${USERNAME} --home ${USER_HOME} \
	&& echo "${USERNAME}:$(openssl rand 512 | openssl sha256 | awk '{print $2}')" | chpasswd \
	&& chown -R ${USERNAME}:${USERGROUP} ${USER_HOME}

# install disco
WORKDIR /tmp/
RUN curl -Ls ${DOWNLOADURL} --output discosrv.tar.gz \
	&& tar -zxf discosrv.tar.gz \
	&& rm discosrv.tar.gz \
	&& mkdir -p ${USER_HOME}/server ${USER_HOME}/certs ${USER_HOME}/db \
	&& cp /tmp/*discosrv*/*discosrv ${USER_HOME}/server/discosrv \
	&& chown -R ${USERNAME}:${USERGROUP} ${USER_HOME}

# cleanup
RUN apt-get --auto-remove -y purge ${BUILD_REQUIREMENTS} \
  	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/*

EXPOSE ${SERV_PORT}

USER discosrv
VOLUME ${USER_HOME}/certs

CMD ${USER_HOME}/server/discosrv \
    -listen=":${SERV_PORT}" \
    -db-dir="${USER_HOME}/db/discosrv.db" \
    -cert="${USER_HOME}/certs/cert.pem" \
    -key="${USER_HOME}/certs/key.pem" \
    ${DISCO_OPTS}
