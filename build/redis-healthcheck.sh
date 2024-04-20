#!/bin/sh

set -eu

check_server() {
  redis-cli PING 2>/dev/null | grep PONG >/dev/null
}

check_cluster() {
  redis-cli cluster info | grep "cluster_state:ok" > /dev/null
}

main() {
  type="${1:-cluster}"
  max_attempts="${2:-1}"

  if [ "$type" = "cluster" ]; then
    cmd="check_cluster"
  else
    cmd="check_server"
  fi

  for _ in $(seq 1 "$max_attempts"); do
    if eval "$cmd"; then
      return
    fi

    sleep 1
  done

  exit 1
}

main "$@"
