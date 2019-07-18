FROM ubuntu:18.04
MAINTAINER Marcello Pucci <califerno@gmail.com>

RUN mkdir /var/run/sshd

RUN mkdir /root/.ssh/

RUN apt-get update && apt-get install -y openssh-server 

RUN echo 'root:aaa' | chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
