#!/bin/bash
apt-get update
apt-get install gettext
envsubst < setupReplicaSet1.js > ../js/setupReplicaSet1.js
envsubst < setupReplicaSet2.js > ../js/setupReplicaSet2.js
envsubst < setupReplicaSet3.js > ../js/setupReplicaSet3.js
envsubst < addShard.js > ../js/addShard.js
