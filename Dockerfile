FROM ubuntu:latest
# Syncthing-Discovery Server

ENV DEBUG           false
ENV SERV_PORT       22026

# Allowed average package rate, per 10 s
ENV LIMIT_AVG       10
# Allowed burst size, packets
ENV LIMIT_BURST     20
# Limiter cache entries
ENV LIMIT_CACHE     25000


RUN apt-get update && \
    apt-get install ca-certificates wget -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    wget -q https://api.github.com/repos/syncthing/discosrv/releases/latest -O- | egrep "browser_download_url.*discosrv-linux-amd64.tar" | cut -d'"' -f4 | xargs wget -o /tmp/discosrv.tar.gz && \
    tar -xzvf /tmp/discosrv.tar.gz && \
    rm /tmp/discosrv.tar.gz


EXPOSE ${SERV_PORT}

RUN groupadd -r discosrv && \
    useradd -r -m -g discosrv discosrv && \
    mv discosrv* /home/discosrv/discosrv && \
    mkdir -p /home/discosrv/certs && \
    mkdir -p /home/discosrv/db && \
    chown -R discosrv:discosrv /home/discosrv

USER discosrv
VOLUME /home/discosrv

CMD /home/discosrv/discosrv/discosrv \
    -listen=":${SERV_PORT}" \
        -limit-avg=${LIMIT_AVG} \
        -limit-cache=${LIMIT_CACHE} \
        -limit-burst=${LIMIT_BURST} \
        -stats-file="/home/discosrv/stats" \
        -db-dsn="file:///home/discosrv/db/discosrv.db" \
        -cert="/home/discosrv/certs/cert.pem" \
        -key="/home/discosrv/certs/key.pem" \
        -debug="${DEBUG}"
