# redis-single-node-cluster

Redis cluster with all slots assigned to a single node for development, testing and CI/CD.

Requires Redis version >= 6.2

## Example

```yaml
# docker-compose.yaml
...
services:
  redis-cluster:
    build:
      context: https://github.com/diorman/redis-single-node-cluster.git#main:build
      args:
        # Defaults to redis:alpine
        - REDIS_BASE_IMAGE=redis:7.2-alpine
    environment:
      # Environment variables prefixed with "REDIS_CONFIG_" are tranformed to
      # kebab-case and added to the config file.
      #
      # The following environment variable is added to the config file as:
      # cluster-announce-ip 127.0.0.1
      - REDIS_CONFIG_CLUSTER_ANNOUNCE_IP=127.0.0.1
    ports:
      - 6379:6379
```

