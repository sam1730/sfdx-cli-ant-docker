FROM ubuntu:16.04
LABEL maintainer="sam1730"

# Install base dependencies
RUN apt-get update \
    && apt-get install -y \
        software-properties-common \
        build-essential \
        ca-certificates \
        wget \
        xvfb \
        xz-utils \
        curl \
        git \
        mercurial \
        maven \
        openjdk-8-jdk \
        ssh-client \
        unzip \
        iputils-ping \
        jq \
    && rm -rf /var/lib/apt/lists/*

# Install nvm with node and npm
ENV NODE_VERSION=8.9.4 \
    NVM_DIR=/root/.nvm \
    NVM_VERSION=0.33.8

RUN curl https://raw.githubusercontent.com/creationix/nvm/v$NVM_VERSION/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# Set node path
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Default to UTF-8 file.encoding
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=C.UTF-8

# Xvfb provide an in-memory X-session for tests that require a GUI
ENV DISPLAY=:99

# Set the path.
ENV PATH=$NVM_DIR:$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Create dirs and users
RUN mkdir -p /opt/atlassian/bitbucketci/agent/build \
    && sed -i '/[ -z \"PS1\" ] && return/a\\ncase $- in\n*i*) ;;\n*) return;;\nesac' /root/.bashrc \
    && useradd --create-home --shell /bin/bash --uid 1000 pipelines

# Apache Ant
ENV ANT_VERSION 1.10.7
ENV ANT_HOME /opt/ant

# Salesforce Ant migration tool
ENV SF_ANT_VERSION 48.0

# Apache Ant installation
RUN cd /tmp \
    && wget http://www.us.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mkdir ant-${ANT_VERSION} \
    && tar -zxvf apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mv apache-ant-${ANT_VERSION} ${ANT_HOME} \
    && rm apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -rf ant-${ANT_VERSION} \
    && rm -rf ${ANT_HOME}/manual \
    && unset ANT_VERSION
ENV PATH ${PATH}:${ANT_HOME}/bin

# Salesforce Ant migration tool installation
RUN cd /tmp \
    && mkdir salesforce-ant-${SF_ANT_VERSION} \
    && wget https://gs0.salesforce.com/dwnld/SfdcAnt/salesforce_ant_${SF_ANT_VERSION}.zip \
    && unzip -d salesforce-ant-${SF_ANT_VERSION} salesforce_ant_${SF_ANT_VERSION}.zip \
    && mv salesforce-ant-${SF_ANT_VERSION}/ant-salesforce.jar ${ANT_HOME}/lib \
    && rm salesforce_ant_${SF_ANT_VERSION}.zip \
    && rm -rf salesforce-ant-${SF_ANT_VERSION} \
    && unset SF_ANT_VERSION

# Install Salesforce CLI binary
RUN mkdir /sfdx \
    && wget -qO- https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-amd64.tar.xz | tar xJ -C sfdx --strip-components 1 \
    && /sfdx/install \
    && rm -rf /sfdx

# Setup CLI exports
ENV SFDX_AUTOUPDATE_DISABLE=false \
  # export SFDX_USE_GENERIC_UNIX_KEYCHAIN=true \
  SFDX_DOMAIN_RETRY=300 \
  SFDX_DISABLE_APP_HUB=true \
  SFDX_LOG_LEVEL=DEBUG \
  TERM=xterm-256color

RUN sfdx --version
RUN sfdx plugins --core

WORKDIR /opt/atlassian/bitbucketci/agent/build
ENTRYPOINT /bin/bash