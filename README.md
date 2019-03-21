# mongoDocker


```
ubuntu@FREE0001:~$ mongo FREE0001:37018
MongoDB shell version v3.6.3
connecting to: mongodb://FREE0001:37018/test
MongoDB server version: 4.1.9
WARNING: shell and server versions do not match
Server has startup warnings: 
2019-03-21T01:18:49.497+0000 I STORAGE  [initandlisten] 
2019-03-21T01:18:49.497+0000 I STORAGE  [initandlisten] ** WARNING: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine
2019-03-21T01:18:49.497+0000 I STORAGE  [initandlisten] **          See http://dochub.mongodb.org/core/prodnotes-filesystem
2019-03-21T01:18:50.508+0000 I CONTROL  [initandlisten] 
2019-03-21T01:18:50.508+0000 I CONTROL  [initandlisten] ** NOTE: This is a development version (4.1.9) of MongoDB.
2019-03-21T01:18:50.508+0000 I CONTROL  [initandlisten] **       Not recommended for production.
2019-03-21T01:18:50.508+0000 I CONTROL  [initandlisten] 
2019-03-21T01:18:50.508+0000 I CONTROL  [initandlisten] ** WARNING: Access control is not enabled for the database.
2019-03-21T01:18:50.509+0000 I CONTROL  [initandlisten] **          Read and write access to data and configuration is unrestricted.
2019-03-21T01:18:50.509+0000 I CONTROL  [initandlisten] 
2019-03-21T01:18:50.509+0000 I CONTROL  [initandlisten] 
2019-03-21T01:18:50.509+0000 I CONTROL  [initandlisten] ** WARNING: /sys/kernel/mm/transparent_hugepage/enabled is 'always'.
2019-03-21T01:18:50.509+0000 I CONTROL  [initandlisten] **        We suggest setting it to 'never'
2019-03-21T01:18:50.510+0000 I CONTROL  [initandlisten] 
my-mongo-set:PRIMARY> 
```
Creating a MongoDB replica set using Docker 🍃
June 30, 2016
architecture diagram
Replication is a technique used my MongoDB to ensure that your data is always backed up for safe keeping, in case one of your database servers decide to crash, shut down or turn into Ultron. Even though replication as a concept sounds easy, it’s quite daunting for newcomers to set up their own replica sets, much less containerize them.
This tutorial is a beginner friendly way to set up your own MongoDB replica sets using docker.

Pre-requisites
The only thing we need installed on our machines is Docker, and… that’s it! We don’t even need to install MongoDB to create our replica set, since we can access the shell through our containers itself.

To verify that you have docker installed run :

docker -v
,which should output the version number. Next, we need to make sure our docker daemon is running. So run :

docker images
,which should output the list of images you currently have on your system.
Next, we will get the latest version of the official Mongo image, by running

docker pull mongo
Great! Now were all set to get up and running.

Overview
We are going to have 3 containers from the mongo image, all inside their own docker container network. Let’s name them mongo1, mongo2, and mongo3. These will be the three mongo instances of our replica set. We are also going to expose each of them to our local machine, so that we can access any of them using the mongo shell interface from our local machine if we need to (you will have to install MongoDB on your own machine to do this). Each of the three mongo container should be able to communicate with all other containers in the network.

architecture diagram
Setting up the network
To see all networks currently on your system, run the command
```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
2a4e341c6039        bridge              bridge              local
4fbef5286425        host                host                local
8062e4e7cdca        none                null                local
We will be adding a new network called my-mongo-cluster :

$ docker network create my-mongo-cluster
The new network should now be added to your list of networks :

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
2a4e341c6039        bridge              bridge              local
4fbef5286425        host                host                local
f65e93c94e42        mongo-cluster       bridge              local
8062e4e7cdca        none                null                local
Setting up our containers
To start up our first container, mongo1 run the command:

$ docker run \
-p 30001:27017 \
--name mongo1 \
--net my-mongo-cluster \
mongo mongod --replSet my-mongo-set
```
Let’s see what each part of this command does :

docker run : Start a container from an image
-p 30001:27017 : Expose port 27017 in our container, as port 30001 on the localhost
--name mongo1 : name this container “mongo1”
--net my-mongo-cluster : Add this container to the “my-mongo-cluster” network.
mongo : the name of the image we are using to spawn this container
mongod --replSet my-mongo-set : Run mongod while adding this mongod instance to the replica set named “my-mongo-set”
Set up the other 2 containers by running :
```
$ docker run \
-p 30002:27017 \
--name mongo2 \
--net my-mongo-cluster \
mongo mongod --replSet my-mongo-set
$ docker run \
-p 30003:27017 \
--name mongo3 \
--net my-mongo-cluster \
mongo mongod --replSet my-mongo-set
```
Remember to run each of these commands in a separate terminal window, since we are not running these containers in a detached state

Setting up replication
Now that we have all our mongo instances up and running, let’s turn them into a replica set.

Connect to the mongo shell in any of the containers.

docker exec -it mongo1 mongo
This command will open up the mongo shell in our running mongo1 container (but you can also run it from the mongo2 or mongo3 container as well).

Inside the mongo shell, we first create our configuration :
```
MongoDB shell version: 2.6.7
> db = (new Mongo('localhost:27017')).getDB('test')
test
> config = {
  	"_id" : "my-mongo-set",
  	"members" : [
  		{
  			"_id" : 0,
  			"host" : "mongo1:27017"
  		},
  		{
  			"_id" : 1,
  			"host" : "mongo2:27017"
  		},
  		{
  			"_id" : 2,
  			"host" : "mongo3:27017"
  		}
  	]
  }
  ```
The first _id key in the config, should be the same as the --replSet flag which was set for our mongod instances, which is my-mongo-set in our case. We then list all the members we want in our replica set. Since we added all our mongo instances to our docker network. Their name in each container resolver to their respective ip addresses in the my-mongo-cluster network.

We finally start the replica set by running
```
> rs.initiate(config)
{ "ok" : 1 }
```
,in our mongo shell. If all goes well, your prompt should change to something like this :

my-mongo-set:PRIMARY>
This means that the shell is currently associated with the PRIMARY database in our my-mongo-set cluster.

Let’s play around with our new replica set to make sure it works as intended. (I am omitting the my-mongo-set:PRIMARY> prompt for readability)

We first insert a document into our primary database :
```
> db.mycollection.insert({name : 'sample'})
WriteResult({ "nInserted" : 1 })
> db.mycollection.find()
{ "_id" : ObjectId("57761827767433de37ff95ee"), "name" : "sample" }
We then make a new connection to one of our secondary databases (located on mongo2) and test to see if our document get replicated there as well :

> db2 = (new Mongo('mongo2:27017')).getDB('test')
test
> db2.setSlaveOk()
> db2.mycollection.find()
{ "_id" : ObjectId("57761827767433de37ff95ee"), "name" : "sample" }
```
We run the db2.setSlaveOk() command to let the shell know that we re intentionally querying a database that is not our primary. And it looks like the same document is present in our secondary as well.

Going forward
As you can see, with the power of docker we were able to get a mongo replica set up and running in ~5 minutes. Although this set up is great to experiment and play around with replica sets, there are some precautions to be taken before moving it to production :

None of the databases have any administrative security measures. Be sure to add users and passwords when deploying this solution on an actual server.
Keeping all containers on a single server is not the best idea. Run at least one container on a different server and access it through its external ip address and port (in our case the external facing ports for out containers were 30001, 30002, and 30003 for mongo1, mongo2, and mongo3 respectively).
In case we remove one of our containers by mistake, the data would also vanish. Using Docker volumes and setting the appropriate --dbpath when running mongod would prevent this from happening.
Finally, instead of running a bunch of shell scripts, you may find it more convenient to automate this whole process by using multi-container automation tools like docker-compose.

If you liked this post, you may also like my other post on building a (very) lightweight web server in docker with busybox and Go
