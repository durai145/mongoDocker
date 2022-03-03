#!/bin/bash
HOSTNAME=`hostname`
mongod --bind_ip $HOSTNAME --replSet my-mongo-set
