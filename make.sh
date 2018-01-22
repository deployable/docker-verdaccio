#!/usr/bin/env bash

NAME="verdaccio"
PATH_APP="/${NAME}"
PORT=4873
RELEASE="2.7.3"
RELEASE_LABEL="${NAME}-${RELEASE}"
RELEASE_FILE="${RELEASE_LABEL}.tar.gz"
TAG_PREFIX="deployable"
TAG_NAME="${NAME}"
TAG_TAG="latest"


rundir=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)")
canonical="$rundir/$(basename -- "$0")"

if [ -n "${1:-}" ]; then
  cmd=$1
  shift
else
  cmd=build
fi

cd "$rundir"

set -uex

# Environment
DOCKER_BUILD_PROXY=${DOCKER_BUILD_PROXY:-}

####

die(){
  echo "ERROR: $@"
  echo "Exiting..."
  exit 1
}

run_build_web(){
  cd "$rundir/$RELEASE_LABEL"
  yarn install
  yarn run build:webui
}

run_build_proxy(){
  DOCKER_BUILD_PROXY=${DOCKER_BUILD_PROXY:-http://10.8.10.8:3142}
  DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:---build-arg DOCKER_BUILD_PROXY=$DOCKER_BUILD_PROXY}
  DOCKER_BUILD_PROXY="$DOCKER_BUILD_PROXY" DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS" run_build
}

run_build(){
  local tag=${1:-${TAG_TAG}}
  DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:-}
  run_download_if_missing
  run_extract_if_missing 
  #run_build_web
  docker build $DOCKER_BUILD_ARGS -t ${TAG_PREFIX}/${TAG_NAME}:${RELEASE} .
  docker tag ${TAG_PREFIX}/${TAG_NAME}:${RELEASE} ${TAG_PREFIX}/${TAG_NAME}:${tag}
}

run_download_if_missing(){
  cd "$rundir"
  if [ ! -f "$RELEASE_FILE" ]; then
    run_download
  fi
}
run_download(){
  cd "$rundir"
  wget -cO "$RELEASE_FILE".tmp "https://github.com/verdaccio/verdaccio/archive/v${RELEASE}.tar.gz"
  mv "${RELEASE_FILE}.tmp" "$RELEASE_FILE"
}
run_extract_if_missing(){
  cd "$rundir"
  if [ ! -d "${RELEASE_LABEL}" ]; then
    run_extract
  fi
}
run_extract(){
  cd "$rundir"
  tar -xvf ${RELEASE_FILE}
}

run_restart(){
  run_stop
  run_start
}

run_rebuild(){
  run_build
  run_restart
}
run_rebuild_proxy(){
  run_build_proxy
  run_restart
}

run_run(){ run_start "$@"; }
run_start(){
  docker run \
    --detach \
    --volume ${NAME}-storage:${PATH_APP}/storage:rw \
    --publish ${PORT}:${PORT} \
    --name ${NAME} \
    --restart always  \
    ${TAG_PREFIX}/${TAG_NAME}:${RELEASE}
}

run_stop(){
  docker stop ${NAME} ||  echo stop failed
  docker rm -f ${NAME} || echo remove failed
}

run_shell(){
  docker exec -ti ${NAME} bash
}

run_logs(){
  docker logs --tail 10 -f ${NAME}
}

run_publish(){
  local tag=${1:-${TAG_TAG}}
  docker push ${TAG_PREFIX}/${TAG_NAME}:${tag}
}

run_release(){
  local release_date=$(date +%Y%m%d-%H%M%S)
  [ -z "$(git status --porcelain)" ] || die "Git status not clean"
  build ${release_date}
  build latest
  test_run
  git push
  git tag -f ${release_date}
  publish $release_date
  publish latest
  git push -f --tags
}

test_start(){
  echo "implement test_start"
}
test_exec(){
  echo "implement test_exec"
}
test_stop(){
  echo "implement test_stop"
}
test_clean(){
  echo "implement test_clean"
}
test_run(){
  test_start
  test_exec
  test_stop
  test_clean
}


####

run_help(){
  echo "Commands:"
  awk '/  ".*"/{ print "  "substr($1,2,length($1)-3) }' make.sh
}

set -x

case $cmd in
  "build")          run_build "$@";;
  "rebuild")        run_rebuild "$@";;
  "rebuild:proxy")  run_rebuild_proxy "$@";;
  "download")       run_download "$@";;
  "build:proxy")    run_build_proxy "$@";;
  "run")            run_run "$@";;
  "restart")        run_restart "$@";;
  '-h'|'--help'|'h'|'help') run_help;;
esac

