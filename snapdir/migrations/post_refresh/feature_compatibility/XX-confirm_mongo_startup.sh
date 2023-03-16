#!/bin/bash

source $SNAP/helpers/mongo.sh

start() {
    # In case if the mongo update fails,
    # and mongod is unable to start up post refresh,
    # this should fail and revert to the local previous
    # revision, avoiding bricking the installs.
    start_mongod && is_mongod_ready && stop_mongod
}
