#!/bin/sh

CONFIG="/usr/local/etc/redis/redis-cluster.conf"

export REDIS_CONFIG_BIND="${REDIS_CONFIG_BIND:-"* -::*"}"
export REDIS_CONFIG_CLUSTER_ANNOUNCE_IP="${REDIS_CONFIG_CLUSTER_ANNOUNCE_IP:-$(hostname -i)}"

create_config() {
  mkdir -p $(dirname $CONFIG)
  echo "cluster-enabled yes" > $CONFIG

  # Map environment variables with the prefix 'REDIS_CONFIG_' into redis config entries and append
  # them to config file.
  #
  # Example:
  #   REDIS_CONFIG_CLUSTER_ANNOUNCE_IP=127.0.0.1 -> cluster-announce-ip 127.0.0.1
  #
  env | grep '^REDIS_CONFIG_' | cut -d'=' -f1 | while read -r redis_config_var; do
    redis_config_name="$(echo "$redis_config_var" | sed 's/^REDIS_CONFIG_//' | sed 's/_/-/g' | tr '[:upper:]' '[:lower:]')"
    echo "$redis_config_name $(eval echo \$${redis_config_var})" >> $CONFIG
  done
}

configure_cluster_slots() {
  slots=$(for slot in $(seq 0 16383); do printf "%s " "$slot"; done)
  set -- $slots
  redis-cli CLUSTER ADDSLOTS "$@" >/dev/null
}

wait_until_ready() {
  until redis-cli PING 2>/dev/null | grep PONG >/dev/null; do
    sleep 1
  done
}

log() {
  echo "[redis-single-node-cluster] $1"
}

main() {
  log "Creating configuration"
  create_config

  log "Starting redis server in the background: $(redis-server --version)"
  redis-server "$CONFIG" &

  log "Waiting for redis server to be ready..."
  wait_until_ready

  log "Configuring cluster slots"
  configure_cluster_slots

  wait
}

main
