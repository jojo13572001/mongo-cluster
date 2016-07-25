FROM        ubuntu:14.04.1
MAINTAINER  Love Nyberg "love@bloglovin.com"
ENV REFRESHED_AT 2014-10-18

RUN touch /etc/apt/sources.list.d/mongodb-org-3.2.list
# Add 10gen official apt source to the sources list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

# Install MongoDB
RUN apt-get update && \
    apt-get install -y mongodb-org=3.2.5 mongodb-org-server=3.2.5 mongodb-org-shell=3.2.5 mongodb-org-mongos=3.2.5 mongodb-org-tools=3.2.5

# Create the MongoDB data directory
RUN mkdir -p /data/db

EXPOSE 27017 

ADD js/initiate.js /initiate.js
ADD js/setupReplicaSet1.js /setupReplicaSet1.js
ADD js/setupReplicaSet2.js /setupReplicaSet2.js
ADD js/setupReplicaSet3.js /setupReplicaSet3.js
ADD js/addShard.js /addShard.js
ADD js/addDBs.js /addDBs.js
ADD js/enableSharding.js /enableSharding.js
ADD js/addIndexes.js /addIndexes.js
ADD start.sh /start.sh

CMD ["/start.sh"]
