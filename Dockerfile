FROM amazoncorretto:25

RUN mkdir -p /opt/minecraft
COPY server.jar /opt/minecraft/server.jar
COPY entrypoint.sh /opt/minecraft/entrypoint.sh

WORKDIR /data

EXPOSE 25565

RUN chmod +x /opt/minecraft/entrypoint.sh

CMD ["/opt/minecraft/entrypoint.sh"]