# we need to have `registry` binary to run garbage collector upon data dir
FROM registry

COPY ./cleanup-registry.sh /
