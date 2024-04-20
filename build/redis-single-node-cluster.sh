#!/bin/sh

set -eu

CONFIG="/usr/local/etc/redis/redis-cluster.conf"

export REDIS_CONFIG_BIND="${REDIS_CONFIG_BIND:-"* -::*"}"
export REDIS_CONFIG_CLUSTER_ANNOUNCE_IP="${REDIS_CONFIG_CLUSTER_ANNOUNCE_IP:-$(hostname -i)}"

create_config() {
  mkdir -p "$(dirname $CONFIG)"
  echo "cluster-enabled yes" > $CONFIG

  # Map environment variables with the prefix 'REDIS_CONFIG_' into redis config entries and append
  # them to config file.
  #
  # Example:
  #   REDIS_CONFIG_CLUSTER_ANNOUNCE_IP=127.0.0.1 -> cluster-announce-ip 127.0.0.1
  #
  env | grep '^REDIS_CONFIG_' | cut -d'=' -f1 | while read -r redis_config_var; do
    redis_config_name="$(echo "$redis_config_var" | sed 's/^REDIS_CONFIG_//' | sed 's/_/-/g' | tr '[:upper:]' '[:lower:]')"
    echo "$redis_config_name $(eval echo \$"${redis_config_var}")" >> $CONFIG
  done
}

configure_cluster_slots() {
  min_slot=0
  max_slot=16383
  version_major="$(redis-cli INFO | grep 'redis_version:' | sed 's/redis_version://' | cut -d'.' -f1)"

  if [ "$version_major" -ge 7 ]; then
    redis-cli CLUSTER ADDSLOTSRANGE "$min_slot" "$max_slot" >/dev/null
    return
  fi

  slots=$(for slot in $(seq "$min_slot" "$max_slot"); do printf "%s " "$slot"; done)
  # shellcheck disable=SC2086
  set -- $slots
  redis-cli CLUSTER ADDSLOTS "$@" >/dev/null
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
  redis-healthcheck.sh server 5

  log "Configuring cluster slots"
  configure_cluster_slots

  wait
}

main
