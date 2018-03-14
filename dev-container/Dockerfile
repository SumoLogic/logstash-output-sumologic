FROM jruby:9.1.16.0-jdk

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y git-all && \
    apt-get install -y wget && \
    apt-get install -y apt-transport-https && \
    apt-get install -y vim

RUN wget https://packages.elastic.co/GPG-KEY-elasticsearch -qO /tmp/GPG-KEY-elasticsearch.key && \
    apt-key add /tmp/GPG-KEY-elasticsearch.key && \
    rm -f /tmp/GPG-KEY-elasticsearch.key

RUN echo 'deb https://artifacts.elastic.co/packages/6.x/apt stable main' | tee -a /etc/apt/sources.list.d/elastic-6.x.list

RUN apt-get update && apt-get install logstash

RUN mkdir -p ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    
RUN cd ~ && \
    git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt --depth=1 && \
    echo GIT_PROMPT_ONLY_IN_REPO=1 >> ~/.bashrc && \
    echo source ~/.bash-git-prompt/gitprompt.sh >> ~/.bashrc

RUN cd ~ && \
    git clone https://github.com/SumoLogic/logstash-output-sumologic.git && \
    cd ~/logstash-output-sumologic && \
    bundle install

RUN echo set tabstop=4 softtabstop=0 expandtab shiftwidth=2 smarttab >> /etc/vim/vimrc.local

RUN echo export PATH=/usr/share/logstash/bin:\$PATH >> ~/.bashrc

WORKDIR /root/logstash-output-sumologic

COPY keep-alive.sh /etc/keep-alive.sh
RUN chmod +x /etc/keep-alive.sh

ENTRYPOINT ["/etc/keep-alive.sh"]
