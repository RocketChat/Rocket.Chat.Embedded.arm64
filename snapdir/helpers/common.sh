#!/bin/bash

source $SNAP/helpers/environment.sh

abort() { exit 1; }

error() {
  printf "[ERROR] %s\n" "$*" >&2
  [[ $(snapctl get ignore-errors) == "true" ]] || abort
}

_jq() {
  # better_jq_* key string extra_options
  local argv=("$@")
  local key=${1?}
  local string=${2?}
  local extra_options=("${argv[@]:2}")


  local jq_args="fromjson? | .$key // "

  # [0]=_jq [1]=better_jq_*
  jq_args+=${FUNCNAME[1]#better_jq_}

  printf "$string" | jq -r -R "$jq_args" "${extra_options[@]}"
}

better_jq_empty() { _jq "$@"; }
better_jq_.() { _jq "$@"; }

get_ip() { getent hosts ${1?} | awk '{ print $1 }'; }

empty() { [[ -z $1 ]]; }
