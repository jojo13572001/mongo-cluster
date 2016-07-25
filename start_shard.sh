#!/bin/bash

# Docker interface ip
#DOCKERIP="172.31.5.27"

if [ $# -ne 2 ]
  then
    echo "Arguments Number Wrong, it should be two: configServer num, masterIP"
    exit
fi

DOCKERIP=$(/sbin/ifconfig docker0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
MASTERIP=$2
ETH0IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
LOCALPATH=$(pwd)
ARGS="s --configdb "
MONGOS_PORT=60000

#  Clean up
echo "claer all mongod"
docker rm -f $(sudo docker ps -a -f 'name=mongos' -q)
docker rm -f $(sudo docker ps -a -f 'name=configserver' -q)

#containers=( configserver1 configserver2 configserver3 mongos1 )
#for c in ${containers[@]}; do
#	docker kill ${c} 
#	docker rm ${c}
#done

callMongodAddress ()
{
	echo $(curl -sb -H "Accept: application/json" "http://$2:8500/v1/catalog/service/mongo") \
       	| (jq -r ".[] | select(.ServiceID | contains(\"registrator:$1:27017\"))")
}

echo Start search shard master ip 
MONGOD1R1=$(callMongodAddress mongod1r1 $2)
MONGOD1R1IP=$(echo ${MONGOD1R1} | jq -r '.ServiceAddress')
MONGOD1R1PORT=$(echo ${MONGOD1R1} | jq -r '.ServicePort')
echo mongod1r1 ${MONGOD1R1IP}:${MONGOD1R1PORT}
MONGOD1R2=$(callMongodAddress mongod1r2 $2)
MONGOD1R2IP=$(echo ${MONGOD1R2} | jq -r '.ServiceAddress')
MONGOD1R2PORT=$(echo ${MONGOD1R2} | jq -r '.ServicePort')
echo mongod1r2 ${MONGOD1R2IP}:${MONGOD1R2PORT}
MONGOD1R3=$(callMongodAddress mongod1r3 $2)
MONGOD1R3IP=$(echo ${MONGOD1R3} | jq -r '.ServiceAddress')
MONGOD1R3PORT=$(echo ${MONGOD1R3} | jq -r '.ServicePort')
echo mongod1r3 ${MONGOD1R3IP}:${MONGOD1R3PORT}
MONGOD2R1=$(callMongodAddress mongod2r1 $2)
MONGOD2R1IP=$(echo ${MONGOD2R1} | jq -r '.ServiceAddress')
MONGOD2R1PORT=$(echo ${MONGOD2R1} | jq -r '.ServicePort')
echo mongod2r1 ${MONGOD2R1IP}:${MONGOD2R1PORT}
MONGOD2R2=$(callMongodAddress mongod2r2 $2)
MONGOD2R2IP=$(echo ${MONGOD2R1} | jq -r '.ServiceAddress')
MONGOD2R2PORT=$(echo ${MONGOD2R2} | jq -r '.ServicePort')
echo mongod2r2 ${MONGOD2R2IP}:${MONGOD2R2PORT}
MONGOD2R3=$(callMongodAddress mongod2r3 $2)
MONGOD2R3IP=$(echo ${MONGOD2R3} | jq -r '.ServiceAddress')
MONGOD2R3PORT=$(echo ${MONGOD2R3} | jq -r '.ServicePort')
echo mongod2r3 ${MONGOD2R3IP}:${MONGOD2R3PORT}

echo "Waiting Generate js command for mongodb replication and sharding"
docker run -i --rm -w /jsTmpl -v $(pwd)/mongo/jsTmpl:/jsTmpl -v $(pwd)/mongo/js:/js \
                -e mongod1r1=${MONGOD1R1IP} \
                -e mongod2r1=${MONGOD2R1IP} \
                -e mongod1r1Port=${MONGOD1R1PORT} \
                -e mongod2r1Port=${MONGOD2R1PORT} \
                -e mongod1r2=${MONGOD1R2IP} \
                -e mongod2r2=${MONGOD2R2IP} \
                -e mongod1r2Port=${MONGOD1R2PORT} \
                -e mongod2r2Port=${MONGOD2R2PORT} \
                -e mongod1r3=${MONGOD1R3IP} \
                -e mongod2r3=${MONGOD2R3IP} \
                -e mongod1r3Port=${MONGOD1R3PORT} \
                -e mongod2r3Port=${MONGOD2R3PORT} \
                ubuntu:14.04.1 /bin/bash /jsTmpl/start.sh
# Uncomment to build mongo image yourself otherwise it will download from docker index.
docker build -t jojo13572001/mongo ${LOCALPATH}/mongo

# Setup skydns/skydock
#docker run -d -p ${DOCKERIP}:53:53/udp --name skydns crosbymichael/skydns -nameserver 8.8.8.8:53 -domain docker
#docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain docker -name skydns
rm -rf ${LOCALPATH}/mongodata/*-cfg
for (( i = 1; i <= $1; i++ )); do
	# Setup local db storage if not exist
	if [ ! -d "${LOCALPATH}/db/${i}-cfg" ]; then
		mkdir -p ${LOCALPATH}/mongodata/${i}-cfg
	fi
	# Create configserver
	docker run --name configserver${i} -p $((50000+${i})):27017 -i -d \
		   -v ${LOCALPATH}/mongodata/${i}-cfg:/data/db \
		   -e OPTIONS="d --configsvr --dbpath /data/db --notablescan --noprealloc --smallfiles --port 27017" \
		   jojo13572001/mongo
        #generate arguments for mongos to setup configure server	
	ARGS="$ARGS${ETH0IP}:$((50000+${i}))"	
	if [ ${i} -ne $1 ]; then
		ARGS="${ARGS},"	
	fi
done

echo "mongo${ARGS}"
sleep 15
# Setup and configure mongo router
echo "setup mongos1 router"
docker run --name mongos1 -p ${MONGOS_PORT}:27017 -i -d -e OPTIONS="${ARGS} --port 27017" jojo13572001/mongo
sleep 15 # Wait for mongo to start
echo "add replication sets to sharding"
docker run -P -i -t --rm -e OPTIONS=" ${DOCKERIP}:${MONGOS_PORT} /addShard.js" jojo13572001/mongo
sleep 15 # Wait for sharding to be enabled
echo "add DBs"
docker run -P -i -t --rm -e OPTIONS=" ${DOCKERIP}:${MONGOS_PORT} /addDBs.js" jojo13572001/mongo
sleep 15 # Wait for db to be created
echo "enable sharding"
docker run -P -i -t --rm -e OPTIONS=" ${DOCKERIP}:${MONGOS_PORT}/admin /enableSharding.js" jojo13572001/mongo
sleep 15 # Wait sharding to be enabled
echo "add indexes"
docker run -P -i -t --rm -e OPTIONS=" ${DOCKERIP}:${MONGOS_PORT} /addIndexes.js" jojo13572001/mongo
echo "#####################################"
echo "MongoDB Cluster is now ready to use"
echo "Connect to cluster by:"
#echo "$ mongo --port $(docker port mongos1 |cut -d ":" -f2)"
