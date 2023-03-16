#!/bin/bash

source $SNAP/helpers/common.sh
source $SNAP/helpers/environment.sh

caddy() { local v=${1?}; shift; caddy${v#v} "$@"; }

start_caddy_v1_with_config() { caddy v1 -conf=$SNAP_DATA/Caddyfile; }

start_caddy_v2_with_config() { caddy v2 run --config=$SNAP_DATA/Caddyfile; }

caddy_v2_reverse_proxy() { caddy v2 reverse-proxy --change-host-header --from=${1?} --to=${2?}; }
