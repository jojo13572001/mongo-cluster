# mongo-cluster
A dockerized mongodb cluster with shard support.
modify from jacksoncage for my personal usage.

#Diagram
![My image](jojo13572001.github.com/repository/images/mongo.jpg)
#Usage
Create Set1 mongod nodes

1.1 Go to you mongod server 172.31.13.64

1.2 Go to your second management node 172.31.1.232

bash start_node.sh -mgmd 0 2 2 1 172.31.13.64 172.31.1.232 172.31.15.42 172.31.14.144 172.31.2.226

# Reference
https://github.com/jacksoncage/mongo-docker
