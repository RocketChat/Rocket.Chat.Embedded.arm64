#! /bin/bash

source $SNAP/helpers/caddy.sh

if [[ -s $SNAP_DATA/Caddyfile ]]; then
  # Prioritize v2 over v1
  start_caddy_v2_with_config || start_caddy_v1_with_config
else
  caddy_v2_reverse_proxy $(snapctl get siteurl) http://127.0.0.1:$(snapctl get port)
fi
