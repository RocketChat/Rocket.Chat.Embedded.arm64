#!/bin/bash

source $SNAP/helpers/mongo.sh

start() {
    local v
    { is_mongod_running || start_mongod; } && is_mongod_ready && v=$(mongod_version_excluding_patch) && is_mongod_primary && { is_feature_compatibility $v || set_feature_compatibility $v; } && stop_mongod
}
