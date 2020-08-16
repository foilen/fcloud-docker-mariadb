# https://hub.docker.com/_/mariadb?tab=tags
FROM mariadb:10.4.14

RUN export TERM=dumb ; \
  apt-get update && apt-get install -y \
    ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN export TERM=dumb ; \
  echo "deb https://dl.bintray.com/foilen/debian stable main" > /etc/apt/sources.list.d/foilen.list \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61 \
  && apt-get update && apt-get install -y \
    haproxy \
    mysql-manager=1.1.1 \
    supervisor \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY assets /
CMD chmod 755 /*.sh

CMD /bin/bash
