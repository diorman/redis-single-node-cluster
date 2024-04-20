#!/bin/bash

set -eu

IMAGE_NAME="local/redis-single-node-cluster"
CONTAINER_NAME="redis-single-node-cluster-test"

build_image() {
  docker build ./build -q --build-arg "REDIS_BASE_IMAGE=$1" -t "$IMAGE_NAME" > /dev/null
}

stop_container() {
  docker stop "$CONTAINER_NAME" &> /dev/null || true
}

run_container() {
  docker run -d --rm --name "$CONTAINER_NAME" "$@" "$IMAGE_NAME" > /dev/null
}

wait_cluster_ready() {
  if docker exec "$CONTAINER_NAME" redis-healthcheck.sh cluster 5; then
    return
  fi

  echo "Gave up waiting for cluster to be ready"
  exit 1
}

get_cluster_announce_ip() {
  docker exec "$CONTAINER_NAME" redis-cli cluster slots | xargs | cut -d' ' -f3
}

assert() {
  message=$1
  assertion=$2

  if [[ ! $assertion ]]
  then
    echo "❌ $message ($assertion)"
    exit 1
  else
    echo "✅ $message"
    return
  fi
}

assert_default_cluster_announce_ip() {
  run_container
  wait_cluster_ready
  container_ip="$(docker exec "$CONTAINER_NAME" hostname -i)"

  assert "Default cluster announce IP matches host IP" "$container_ip == $(get_cluster_announce_ip)"

  stop_container
}

assert_custom_cluster_announce_ip() {
  run_container -e "REDIS_CONFIG_CLUSTER_ANNOUNCE_IP=127.0.0.1"
  wait_cluster_ready

  assert "Cluster announce IP matches custom value" "127.0.0.1 == $(get_cluster_announce_ip)"

  stop_container
}


main() {
  redis_base_image="$1"
  echo "Running tests for redis image: $redis_base_image"

  # stop the test container in case it is running
  stop_container
  build_image "$redis_base_image"

  assert_default_cluster_announce_ip
  assert_custom_cluster_announce_ip
}

main "$@"
