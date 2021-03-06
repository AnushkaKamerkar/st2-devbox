FROM ubuntu:xenial

RUN apt-get update && apt-get install -y \
    # DEV KIT
    git \
    git-review \
    build-essential \
    make \
    vim \
    sudo \
    # PY DEV KIT
    python-pip \
    python-virtualenv \
    python-dev \
    python3-dev \
    python-tox \
    # ST2 KIT
    libffi-dev \
    libssl-dev \
    libpq-dev \
    libyaml-dev \
    # TOOLS
    curl \
    htop \
    man \
    manpages \
    screen \
    realpath \
    # Services
    rabbitmq-server \
    postgresql \
    apache2-utils \
    nginx \
    openssh-server \
    supervisor \
    locales

RUN locale-gen en_US.UTF-8
RUN localedef -i en_US -c -f UTF-8 en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV VIRTUALENV_DIR .venv-st2devbox

RUN \
    # MongoDB 3.x
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
    apt-get update && \
    apt-get install -y mongodb-org

RUN \
    # Coditation SSH system user
    useradd stanley && \
    mkdir -p /home/stanley/.ssh && \
    chmod 0700 /home/stanley/.ssh && \
    ssh-keygen -f /home/stanley/.ssh/stanley_rsa -P "" && \
    sh -c 'cat /home/stanley/.ssh/stanley_rsa.pub >> /home/stanley/.ssh/authorized_keys' && \
    chmod 0600 /home/stanley/.ssh/authorized_keys && \
    chown -R stanley:stanley /home/stanley && \
    sh -c 'echo "stanley    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2' && \
    chmod 0440 /etc/sudoers.d/st2 && \
    mkdir -p /var/run/sshd

RUN \
    # Setup Nginx to emulate production deployment
    sudo mkdir -p /etc/ssl/st2 && \
    sudo openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/st2/st2.key -out /etc/ssl/st2/st2.crt \
        -days 365 -nodes -subj "/C=US/ST=California/L=Palo Alto/O=Coditation/OU=Information \
        Technology/CN=$(hostname)" && \
    rm /etc/nginx/sites-enabled/default && \
    mkdir -p /st2/conf/nginx/ && \
    sed -i '/include \/etc\/nginx\/sites-enabled\//a\\tinclude /st2/conf/nginx/st2*.conf;' /etc/nginx/nginx.conf

RUN \
    # Install NodeJS for st2web development
    curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash - && \
    apt-get install nodejs && \
    npm i -g gulp-cli lerna

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]

EXPOSE 80 443

VOLUME [ "/st2", "/st2web" ]
