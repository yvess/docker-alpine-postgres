FROM alpine:3.1

ENV LANG en_US.utf8
ENV POSTGRES_MAJOR 9.3
ENV POSTGRES_VERSION 9.3.7-r0

RUN apk add --update curl postgresql=9.3.7-r0 && \
    curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.4/gosu-amd64" && \
    chmod +x /usr/local/bin/gosu && \
    apk del curl && \
    rm -rfv /var/cache/apk/*

ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["postgres"]

EXPOSE 5432
