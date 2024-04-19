ARG REDIS_BASE_IMAGE=redis:alpine
FROM $REDIS_BASE_IMAGE

COPY ./redis-single-node-cluster.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/redis-single-node-cluster.sh

CMD ["redis-single-node-cluster.sh"]
