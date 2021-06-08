FROM docker:20.10.7-dind as build
COPY tmp/docker-plugins.tgz .
RUN mkdir -p /tmp/docker-plugins && \
    tar xf docker-plugins.tgz -C /tmp/docker-plugins

FROM docker:20.10.7-dind
COPY --from=build /tmp/docker-plugins /var/lib/docker/plugins/
