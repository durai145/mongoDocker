sudo docker run -d -p 37018:27017 --net my-mongo-cluster --name mdbrp001 -it 36149edebefd
sudo docker run -d -p 47018:27017 --net my-mongo-cluster --name mdbrp002 -it 36149edebefd
sudo docker run -d -p 57018:27017 --net my-mongo-cluster --name mdbrp003 -it 36149edebefd
