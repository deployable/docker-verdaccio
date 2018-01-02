# first
#
#     docker build -t deployable/verdaccio .

# repeat
# 
#     docker build --build-arg DOCKER_BUILD_PROXY=http://10.8.8.8:3142 -t deployable/verdaccio . && docker stop sinopia && docker rm sinopia && docker run -v sinopia-storage:/sinopia/storage:rw -p 4873:4873 -d --name sinopia --restart always deployable/sinopia

FROM node:8.9-alpine

ARG DOCKER_BUILD_PROXY=''

RUN set -uex; \
    npm install -g -s --no-progress yarn@0.28.4 --pure-lockfile; \
    rm -rf ~/.npm;

RUN set -uex; \
    adduser -D -g "" app; \
    adduser -D -g "" -G app appr; \
    mkdir -p /app/storage; \
    chown app /app/storage; \
    chmod 755 /app/storage;

COPY verdaccio-2.7.1 /app

# Use a custom verdaccio config
ADD /config.yaml /app/config.yaml

RUN set -uex; \
    export http_proxy=${http_proxy:-${DOCKER_BUILD_PROXY}}; \
    apk update; \
    apk add g++ python-dev make; \
    export http_proxy=; \
    cd /app; \
    yarn install --production=true --pure-lockfile; \
    yarn cache clean; \
    rm -rf /usr/local/share/.cache/yarn; \
    apk del --purge python python-dev g++ musl-dev libc-dev gcc; \
    rm -rf /var/cache/apk;

RUN set -uex; \
    touch /app/htpasswd; \
    chown -R app:app /app; \
    chown -R appr:app /app/storage; \
    chmod 755 /app/bin/verdaccio; \
    chown appr:app /app/htpasswd; \
    chmod 640 /app/htpasswd; \
    find /app -type d -exec chmod 755 {} +; \
    find /app -type f -exec chmod o+r {} +; \
    find /app -type f -exec chmod g+r {} +;


ADD /entrypoint.sh /docker-entrypoint.sh
USER appr
EXPOSE 4873
ENV PORT 4873
ENV PROTOCOL http
VOLUME ["/app/storage"]
#ENTRYPOINT ["/docker-entrypoint.sh"]
ENTRYPOINT []
CMD ["node", "--trace_gc", "/app/bin/verdaccio", "--config", "/app/config.yaml"]

