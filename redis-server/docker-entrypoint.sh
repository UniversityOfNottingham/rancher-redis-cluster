#!/bin/bash

REDIS_MASTER_NAME=mymaster

REDIS_DATA_FOLDER="/data/redis/$(hostname)"
mkdir -p $REDIS_DATA_FOLDER
chown redis:redis $REDIS_DATA_FOLDER

giddyup service wait scale --timeout 120
my_ip=$(giddyup ip myip)
master_ip=$(giddyup leader get)

# Check if there are sentinel nodes up and running, because current redis cluster master may be different than rancher elected master
if redis-cli -h redis-sentinel -p 26379 ping; then
	master_ip=$(redis-cli -h redis-sentinel -p 26379 --raw sentinel get-master-addr-by-name ${REDIS_MASTER_NAME} | head -n 1)
fi

sed -i -E "s/^ *bind +.*$/bind 0.0.0.0/g" /usr/local/etc/redis/redis.conf
sed -i -E "s|^ *dir +.*$|dir ${REDIS_DATA_FOLDER}|g" /usr/local/etc/redis/redis.conf

if [ "${REDIS_APPENDONLY}" = "yes" ]; then
	sed -i -E "s/^ *appendonly +.*$/appendonly yes/g" /usr/local/etc/redis/redis.conf
fi

if [ -n "${REDIS_TIMEOUT}" ]; then
	sed -i -E "s/^[ #]*timeout .*$/timeout ${REDIS_TIMEOUT}/" /usr/local/etc/redis/redis.conf
fi

if [ ! -z "$REDIS_PASSWORD" ]; then
    sed -i -E "s/^[ #]*masterauth .*$/masterauth ${REDIS_PASSWORD}/" /usr/local/etc/redis/redis.conf
    sed -i -E "s/^[ #]*requirepass .*$/requirepass ${REDIS_PASSWORD}/" /usr/local/etc/redis/redis.conf
fi

if [ "$my_ip" == "$master_ip" ]
then
  sed -i -E "s/^ *slaveof/# slaveof/g" /usr/local/etc/redis/redis.conf
  echo "I am the leader"
else
  port=`echo -n $(grep -E "^ *port +.*$" /usr/local/etc/redis/redis.conf | sed -E "s/^ *port +(.*)$/\1/g")`
  sed -i -E "s/^.*slaveof +.*$/slaveof $master_ip $port/g" /usr/local/etc/redis/redis.conf
fi

exec docker-entrypoint.sh "$@"
