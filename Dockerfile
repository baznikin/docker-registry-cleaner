# we need to have `registry` binary to run garbage collector upon data dir
FROM registry

# Every Saturday at 01:00AM
ENV CLEAN_SCHEDULE "0 1 * * 6"

# supersonic - Cron for containers
ENV SUPERCRONIC_VER=v0.1.12
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64

RUN apk add --no-cache curl
RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

COPY ./entrypoint.sh /
COPY ./cleanup-registry.sh /
RUN chmod +x /cleanup-registry.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/supercronic", "/tmp/crontab" ]
