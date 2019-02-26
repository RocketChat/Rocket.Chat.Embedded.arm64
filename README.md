# Rocket.Chat.Embedded.arm64
An open source journey bringing the latest Rocket.Chat releases to the arm64 universe


## problems with mongo support
Default snap VM's mongodb is only at 2.6.0 - Rocket.Chat no longer supports it.  Must use other means to sideload the latest supported mongo.

### 3.2 has no arm support
Rocket.Chat now requires minimum 3.2 mongodb.  But mongodb does not support ARM for 3.2.

### mongo supports MMAPv1 only for x86
mongoDB support aarch64  BUT it does not support MMAPv1 storage engine on anything ourside of x86 architecture.   This forces us to use WiredTiger engine for the snap.   
