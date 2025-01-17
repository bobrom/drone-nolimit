FROM golang:1.22.10-bookworm as build

ENV DRONE_VERSION=2.25.0

RUN apt-get update && \
    apt-get install --no-install-recommends --assume-yes \
    ca-certificates git build-essential
RUN mkdir -p /src/drone && \
    cd /src/drone && \
    git clone https://github.com/drone/drone . && \
    git checkout tags/v${DRONE_VERSION} -b v${DRONE_VERSION}
RUN cd /src/drone/cmd/drone-server && go build -tags "nolimit" -ldflags "-extldflags \"-static\"" -o drone-server

FROM alpine:3.16.1

EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=false

COPY --from=build /src/drone/cmd/drone-server/drone-server /bin/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ENTRYPOINT ["/bin/drone-server"]
