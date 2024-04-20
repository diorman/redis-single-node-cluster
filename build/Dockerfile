ARG REDIS_BASE_IMAGE=redis:alpine
FROM $REDIS_BASE_IMAGE

COPY ./redis-single-node-cluster.sh ./redis-healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/redis-single-node-cluster.sh /usr/local/bin/redis-healthcheck.sh

HEALTHCHECK --interval=5s CMD ["redis-healthcheck.sh", "cluster"]

CMD ["redis-single-node-cluster.sh"]
