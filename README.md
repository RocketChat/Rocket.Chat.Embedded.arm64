# Rocket.Chat.Embedded.arm64
An open source journey bringing the latest Rocket.Chat releases to the arm64 universe

Latest version is: 4.5.5 of Rocket.Chat

MongoDB has been updated to 4.3.6.23 for arm64 snaps

mongoDB support aarch64  BUT it does not support MMAPv1 storage engine on anything ourside of x86 architecture.   This forces us to use WiredTiger engine for the arm64 snap.   
