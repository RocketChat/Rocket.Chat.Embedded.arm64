#! /bin/bash

source $SNAP/helpers/common.sh

MAX_MONGOD_START_WAIT_SECONDS=1
MAX_MONGOD_START_RETRY_COUNT=30
MAX_MONGOD_PRIMARY_WAIT_SECONDS=5
MAX_MONGOD_PRIMARY_RETRY_COUNT=10

is_mongod_running() {
  local pid_file
  if ! pid_file=$(yq -e e .processManagement.pidFilePath $SNAP_DATA/mongod.conf); then
    [[ -n $(pgrep -xf "mongod --config=$SNAP_DATA/mongod.conf --fork --syslog") ]]
  else [[ -d /proc/$(cat $pid_file) ]]; fi
}

start_mongod() {
  mongod --config=$SNAP_DATA/mongod.conf --fork --syslog || error "mongo server start failed"
}

stop_mongod() {
  mongod --dbpath=$SNAP_COMMON --shutdown || error "mongo server shutdown failed"
}

mongo_eval() {
  mongo --quiet --eval "${1?}"
}

mongod_version_excluding_patch() {
    mongo_eval 'db.version().split(".").slice(0, 2).join(".")'
}

mongo_eval_with_error_check() {
  # 1: command 2: errormsg
  local command=${1?}
  local errmsg=$2
  local output=$(mongo_eval "$command")
  local ok=$(better_jq_empty ok $output)

  (( ${ok:-0} )) && echo $output && return

  better_jq_. errmsg $output >&2
  error ${errmsg:-"$command" command failed}
}

is_mongod_ready() {
  local ok
  for _ in $(seq 0 $MAX_MONGOD_START_RETRY_COUNT); do

    ok=$(mongo_eval 'db.adminCommand({ ping: 1 }).ok') && (( ${ok:-0} )) && return

    sleep $MAX_MONGOD_START_WAIT_SECONDS

  done
  error "mongod server start wait timed out"
}

is_mongod_primary() {
  for _ in $(seq 0 $MAX_MONGOD_PRIMARY_RETRY_COUNT); do

    [[ $(mongo_eval 'db.hello().isWritablePrimary') == "true" ]] && return

    sleep $MAX_MONGOD_PRIMARY_WAIT_SECONDS

  done
  error "primary selection wait timed out"
}

is_feature_compatibility() {
    local v=$(
        mongo_eval_with_error_check '
            JSON.stringify(db.adminCommand({
                getParameter: 1,
                featureCompatibilityVersion: 1
            }))
        '
    )
    test "$(better_jq_. featureCompatibilityVersion.version $v)" == "$1"
}

set_feature_compatibility() {
    mongo_eval_with_error_check "JSON.stringify(db.adminCommand({ setFeatureCompatibilityVersion: \"$1\" }))"
}
