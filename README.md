# Rocket.Chat.Embedded.arm64
An open source journey bringing the latest Rocket.Chat releases to the arm64 universe

Latest version is: 1.3.2 of Rocket.Chat

### mongo supports MMAPv1 only for x86
MongoDB has been updated to 3.4 for arm64 snaps

mongoDB support aarch64  BUT it does not support MMAPv1 storage engine on anything ourside of x86 architecture.   This forces us to use WiredTiger engine for the snap.   
