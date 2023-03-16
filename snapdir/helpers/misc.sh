#! /bin/bash

get_envs() { find $SNAP_DATA $SNAP_COMMON -maxdepth 1 -regex '.*\.env$'; }

init_user_environment_variables() {
  # Check both $SNAP_COMMON and $SNAP_DATA
  # I was hoping this to work without a for loop like this
  # find $SNAP_COMMON $SNAP_DATA -maxdepth 1 -regex '.*\.env$' \
  #  | while read filename; do source $filename; done
  set -a; for filename in `get_envs`; do source $filename; done; set +a
}

# list migration scripts based on where it's called (pre-refresh/post-refresh)
get_migrations() { local __=${0##*/}; find -L $SNAP/migrations/${__/-/_} -perm /111 -type f; }
