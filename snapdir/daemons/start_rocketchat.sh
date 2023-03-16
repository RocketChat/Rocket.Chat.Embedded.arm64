#! /bin/bash

source $SNAP/helpers/rocketchat.sh

[[ $(snapctl get siteurl) =~ ^https:// ]] && snapctl start rocketchat-server.rocketchat-caddy

start_rocketchat
