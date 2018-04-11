FROM mariadb:10.3.5

RUN export TERM=dumb ; \
  echo "deb https://dl.bintray.com/foilen/debian stable main" > /etc/apt/sources.list.d/foilen.list \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61 \
  && apt-get update && apt-get install -y \
    haproxy=1.5.8-3+deb8u2 \
    mysql-manager=1.1.0 \
    supervisor=3.0r1-1+deb8u1 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY assets /
CMD chmod 755 /*.sh

CMD /bin/bash
