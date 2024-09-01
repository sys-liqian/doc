FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /root
ENV LANG=C.UTF-8
SHELL [ "/bin/bash", "-c" ]

RUN echo "deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list
    
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y vim curl git wget iputils-ping tree gcc make tar unzip

RUN apt-get install -y openssh-server && \ 
    mkdir /var/run/sshd && \
    echo "root:root" | chpasswd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile && \
    echo "Host *" >> /root/.ssh/config && \
    echo "    StrictHostKeyChecking no" >> /root/.ssh/config && \
    echo "    GlobalKnownHostsFile  /dev/null" >> /root/.ssh/config && \
    echo "    UserKnownHostsFile    /dev/null" >> /root/.ssh/config && \
    service ssh restart

RUN git config --global user.name liqian35 && \
    git config --global user.email liqian35@lenovo.com && \
    ssh-keygen -t rsa -b 4096 -C "liqian35@lenovo.com" -f /root/.ssh/id_rsa -N "" -q

RUN apt clean && apt autoclean && apt -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD go1.23.0.linux-amd64.tar.gz /usr/local
 
RUN echo "export PATH=$PATH:/usr/local/go/bin:/root/go/bin" >> /etc/profile && \
    echo "export GOPROXY=https://goproxy.cn" >> /etc/profile && \
    echo "export CGO_ENABLED=1" >> /etc/profile
    
EXPOSE 20022
CMD ["/usr/sbin/sshd", "-p", "20022","-D"]
