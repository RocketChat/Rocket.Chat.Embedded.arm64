#!/bin/bash

>/dev/null cat <<CommentEnd

If the user is updating from revision 1502,
he/she might face the "find -executable" issue, which can only be
avoided by setting ignore-erros to true (sudo snap set ignore-errors=true)

With revision 1506, that bug has been fixed. This migration, revision 1507,
makes sure ignore-errors is set back to false, in case the user misses it.

ignore-errors is aa failsafe, not to be kept always enabled.

CommentEnd

start() {
  snapctl set ignore-errors=false
}
