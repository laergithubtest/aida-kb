FROM openjdk:8-jdk

RUN echo 'deb http://ftp.de.debian.org/debian jessie main' >> /etc/apt/sources.list
RUN echo 'deb http://security.debian.org/debian-security jessie/updates main ' >> /etc/apt/sources.list
RUN echo 'deb http://ftp.de.debian.org/debian sid main' >> /etc/apt/sources.list

WORKDIR /root

RUN apt-get update

# Install Python
RUN apt-get -y install python3.6 python3.6-distutils python3.6-dev
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.6 get-pip.py

# set python 3 as the default python version
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1
RUN pip install --upgrade pip requests setuptools pipenv

RUN echo $(python --version)

RUN apt-get install -y libpq-dev libfreetype6-dev libxft-dev libncurses-dev libopenblas-dev gfortran libblas-dev liblapack-dev libatlas-base-dev zlib1g-dev g++
RUN apt-get install -y libpoppler-cpp-dev pkg-config
#RUN apt-get install -y libxml2 libxml2-dev libxslt-dev
RUN apt-get install -y libreoffice
RUN apt-get install -y libenchant1c2a
RUN apt-get install -y git
RUN apt-get install -y vim

RUN apt-get install -y libmagic-dev

RUN apt-get install -y maven

#RUN pip install --upgrade

ARG gitusername
ARG gitpassword

RUN git clone "https://$gitusername:$gitpassword@github.com/laergithubtest/constants.git" && cd /root/constants && git checkout master && git checkout -b deploy v2018.12.17.6
WORKDIR /root/constants/python/aida-common
RUN /bin/bash install_requirements.sh
RUN python install.py

COPY code/ /root/aida-kb

WORKDIR /root/aida-kb
RUN python setup.py install

ADD run.sh /root/aida-kb
RUN chmod +x run.sh

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.2.1/wait /wait
RUN chmod +x /wait

### building solr index
ARG maven
RUN echo $maven

RUN mkdir /root/.m2
RUN echo "$maven" >> /root/.m2/settings.xml

WORKDIR /root
RUN git clone "https://$gitusername:$gitpassword@github.com/laergithubtest/search-indexer.git" && cd /root/search-indexer && git checkout master && git checkout -b deploy v2018.12.17.3

WORKDIR /root

CMD /wait && cd /root/aida-kb && /bin/bash -e run.sh && cd /root/search-indexer && /bin/bash -e build.sh
