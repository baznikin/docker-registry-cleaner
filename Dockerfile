# we need to have `registry` binary to run garbage collector upon data dir
FROM registry

# Every Saturday at 01:00AM
ENV CLEAN_SCHEDULE "0 1 * * 6"

COPY ./cleanup-registry.sh /
RUN chmod +x /cleanup-registry.sh

RUN echo "$CLEAN_SCHEDULE /cleanup-registry.sh" > /etc/crontabs/root
ENTRYPOINT [ "crond" ]
CMD [ "-f", "-l", "6", "-L", "/dev/stdout" ]