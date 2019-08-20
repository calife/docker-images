FROM ubuntu:18.04
MAINTAINER Marcello Pucci <califerno@gmail.com>

RUN mkdir /var/run/sshd

RUN mkdir /root/.ssh/

RUN apt-get update && apt-get install -y openssh-server supervisor

# WORKDIR /app
# COPY create-pwd.sh ./create-pwd.sh
# RUN chmod a+x ./create-pwd.sh
# RUN ./create-pwd.sh
# RUN (cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)>/tmp/one
# RUN cat /tmp/one
# RUN echo "root:$P" | chpasswd

RUN echo "root:aaa" | chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
