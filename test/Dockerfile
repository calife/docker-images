FROM openjdk:8
RUN apt-get -y update
# COPY ./DataService.class /usr/services/dataservice/
# WORKDIR /usr/services/dataservice
# CMD ["java", "DataService"]
WORKDIR /app
COPY . /app
EXPOSE 80
# CMD find .
ENTRYPOINT sh /app/run.sh
# CMD ["/usr/bin/wc","--help"]
