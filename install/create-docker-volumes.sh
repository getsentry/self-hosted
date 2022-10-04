echo "${_group}Creating volumes for persistent storage ..."

function create_docker_volume {
  local name=$1
  echo "Created $(docker volume create --name=$name)."
}

create_docker_volume "sentry-clickhouse"
create_docker_volume "sentry-data"
create_docker_volume "sentry-kafka"
create_docker_volume "sentry-postgres"
create_docker_volume "sentry-redis"
create_docker_volume "sentry-symbolicator"
create_docker_volume "sentry-zookeeper"

echo "${_endgroup}"
