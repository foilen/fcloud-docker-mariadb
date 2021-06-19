# https://hub.docker.com/_/mariadb?tab=tags
FROM mariadb:10.6.2

RUN export TERM=dumb ; \
  apt-get update && apt-get install -y \
    ca-certificates \
    wget \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget https://deploy.foilen.com/mysql-manager/mysql-manager_1.1.2_amd64.deb && \
  dpkg -i mysql-manager_1.1.2_amd64.deb && \
  rm mysql-manager_1.1.2_amd64.deb

COPY assets /
CMD chmod 755 /*.sh

CMD /bin/bash
