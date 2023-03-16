#!/bin/bash

init_mongod_conf() {
  cat >$SNAP_DATA/mongod.conf <<EOF

# For documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# processManagement::fork and systemlog::* are ignored

net:
  bindIp: 127.0.0.1
  port: 27017

setParameter:
  enableLocalhostAuthBypass: false

storage:
  dbPath: $SNAP_COMMON
  journal:
    enabled: true

systemLog:
  destination: syslog

replication:
  replSetName: rs0

processManagement:
  pidFilePath: $SNAP_COMMON/mongod.pid

EOF
}

add_siteurl_environment_variable() {
  local siteurl=$(snapctl get siteurl)
  if [[ $siteurl =~ ^https:// ]]; then
    cat > $SNAP_DATA/OVERWRITE_SETTING_Site_Url.env << EOF
# It is recommended to use snap configuration
# to update the Site_Url value.
# sudo snap set rocketchat-server siteurl=\${Site_Url}

# You can set it manually from here as well,
# but remember whenever you change any of the other configurations
# of this snap, siteurl will switch back to what you set using
# snap set initially.

OVERWRITE_SETTING_Site_Url=$siteurl
EOF
  fi
}

init_default_snap_configurations() {
  port=$(snapctl get port)
  [[ -z $port ]] && { snapctl set port=3000; port=3000; }

  url=$(snapctl get caddy-url)
  [[ -z $url ]] && url=$(snapctl get siteurl)
  [[ -n $url ]] && snapctl set siteurl=$url || snapctl set siteurl=http://localhost:$port

  [[ -n $(snapctl get mongo-url) ]] || snapctl set mongo-url=mongodb://localhost:27017/parties
  [[ -n $(snapctl get mongo-oplog-url) ]] || snapctl set mongo-oplog-url=mongodb://localhost:27017/local
  [[ -n $(snapctl get backup-on-refresh) ]] || snapctl set backup-on-refresh=disable

  [[ -n $(snapctl get ignore-errors) ]] || snapctl set ignore-errors=false

  snapctl unset snap-refreshing
  snapctl unset caddy
  snapctl unset caddy-url
  snapctl unset https
  snapctl unset db-feature-compatibility-version
}

init_extra_environment_variables() {
  cat>$SNAP_DATA/Rocker.Chat.Extra.env<<EOF
# DO NOT UPDATE unless you know what you're doing
XDG_DATA_HOME=\$SNAP/usr/share
FONTCONFIG_PATH=\$SNAP/etc/fonts/config.d
FONTCONFIG_FILE=\$SNAP/etc/fonts/fonts.conf
BABEL_CACHE_DIR=/tmp
EOF
}

start() {
  [[ -f $SNAP_DATA/Rocket.Chat.Extra.env ]] || init_extra_environment_variables
  [[ -f $SNAP_DATA/mongod.conf ]] || init_mongod_conf
  init_default_snap_configurations
  add_siteurl_environment_variable
}

