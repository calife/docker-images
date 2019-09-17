FROM openjdk:8
RUN apt-get -y update
COPY ./DataService.class /usr/services/dataservice/
WORKDIR /usr/services/dataservice
CMD ["java", "DataService"]
