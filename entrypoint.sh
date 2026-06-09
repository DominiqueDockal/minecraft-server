#!/bin/sh
set -e

EULA_VALUE=${EULA:-"true"}

echo "eula=${EULA_VALUE}" > /data/eula.txt

exec java -Xmx1G -Xms1G -jar /opt/minecraft/server.jar nogui