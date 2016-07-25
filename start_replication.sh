#!/bin/bash

if [ $# -lt 2 ]
  then
    echo "Arguments Number Wrong, it should be three: set_index shard_index [Ips]"
    exit
fi

# Docker interface ip
DOCKERIP=$(/sbin/ifconfig docker0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
MASTERIP=$3
ETH0IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
LOCALPATH=$(pwd)
#DNS_HOSTNAME=mongodr$2.mongo.dev.docker
#DNS_NAME=mongodr$2.mongo.dev.docker

#echo "clear mongod DNS"
#docker kill mongodr$2DNS
#docker rm mongodr$2DNS
echo "claer all configserver"
docker rm -f $(sudo docker ps -a -f 'name=configserver' -q)
docker rm -f $(sudo docker ps -a -f 'name=mongos' -q) 

echo "claer all smaller mongod"
for (( i = 1; i <= $1; i++ )); do
for (( j = 1; j <= $2; j++ )); do
	echo "kill mongod${i}r${j}"
	docker kill mongod${i}r${j} 
	docker rm mongod${i}r${j}	
done
done

if [ $2 -eq 1 ]; then
if [ $# -ne 8 ]
  then
    echo "Arguments Number Wrong, it should be three: set_index shard_index 1r1Ip 1r2Ip 1r3Ip 2r1Ip 2r2Ip 2r3Ip"
    exit
fi
	echo Start generate replication ip for template
	MONGOD1R1IP=$3
	MONGOD1R1PORT=$((1*10000+1))
	echo mongod1r2 ${MONGOD1R1IP}:${MONGOD1R1PORT}

	MONGOD1R2IP=$4
	MONGOD1R2PORT=$((2*10000+1))
	echo mongod1r2 ${MONGOD1R2IP}:${MONGOD1R2PORT}

	MONGOD1R3IP=$5
	MONGOD1R3PORT=$((3*10000+1))
	echo mongod1r3 ${MONGOD1R3IP}:${MONGOD1R3PORT}

	MONGOD2R1IP=$6
	MONGOD2R1PORT=$((1*10000+2))
	echo mongod2r1 ${MONGOD2R1IP}:${MONGOD2R1PORT}

	MONGOD2R2IP=$7
	MONGOD2R2PORT=$((2*10000+2))
	echo mongod2r2 ${MONGOD2R2IP}:${MONGOD2R2PORT}

	MONGOD2R3IP=$8
	MONGOD2R3PORT=$((3*10000+2))
	echo mongod2r3 ${MONGOD2R3IP}:${MONGOD2R3PORT}

	echo "Waiting Generate js command for mongodb replication and sharding"
	docker run -i --rm -w /jsTmpl -v $(pwd)/mongo/jsTmpl:/jsTmpl -v $(pwd)/mongo/js:/js \
		-e mongod1r1=${MONGOD1R1IP} \
		-e mongod2r1=${MONGOD2R1IP} \
		-e mongod1r1Port=${MONGOD1R1IP} \
		-e mongod2r1Port=${MONGOD2R1IP} \
		-e mongod1r2=${MONGOD1R2IP} \
		-e mongod2r2=${MONGOD2R2IP} \
		-e mongod1r2Port=${MONGOD1R2PORT} \
		-e mongod2r2Port=${MONGOD2R2PORT} \
		-e mongod1r3=${MONGOD1R3IP} \
		-e mongod2r3=${MONGOD2R3IP} \
		-e mongod1r3Port=${MONGOD1R3PORT} \
		-e mongod2r3Port=${MONGOD2R3PORT} \
		ubuntu:14.04.1 /bin/bash /jsTmpl/start.sh
fi

# Uncomment to build mongo image yourself otherwise it will download from docker index.
echo "Waiting build jojo13572001/mongo images"
docker build -t jojo13572001/mongo ${LOCALPATH}/mongo

rm -rf ${LOCALPATH}/mongodata/*-$2
echo "Waiting setup replication"
#for (( i = 1; i <= $1; i++ )); do
	# Setup local db storage if not exist
	if [ ! -d "${LOCALPATH}/db/$1-$2" ]; then
		mkdir -p ${LOCALPATH}/mongodata/$1-$2
		#mkdir -p ${LOCALPATH}/mongodata/${i}-cfg
	fi
	# Create mongod servers
	echo "create mongod server$1r$2"
	docker run --name mongod$1r$2 -p $(($2*10000+$1)):27017 -i -d \
		-v ${LOCALPATH}/mongodata/$1-$2:/data/db \
		-e OPTIONS="d --replSet set$1 --dbpath /data/db --notablescan --noprealloc --smallfiles --port 27017" jojo13572001/mongo
	if [ $2 -eq 1 ]; then
		sleep 20 
		# Setup replica set
		echo "start initialize replication set mongod$1r1"
		docker run -P -i -t --rm \
			-e OPTIONS=" ${DOCKERIP}:$(($2*10000+$1)) /initiate.js" jojo13572001/mongo
		sleep 30 # Waiting for set to be initiated
		echo "start setup replication set mongod$1r1"
		docker run -P -i -t --rm \
			-e OPTIONS=" ${DOCKERIP}:$(($2*10000+$1)) /setupReplicaSet$1.js" jojo13572001/mongo
	fi
#done
echo "Finish create mongod"
