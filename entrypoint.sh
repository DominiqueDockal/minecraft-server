#!/bin/sh
set -e

EULA_VALUE=${EULA:-"true"}
MEMORY_VALUE=${MEMORY:-"1G"}

echo "eula=${EULA_VALUE}" > /data/eula.txt

exec java -Xmx${MEMORY_VALUE} -Xms${MEMORY_VALUE} -jar /opt/minecraft/server.jar nogui