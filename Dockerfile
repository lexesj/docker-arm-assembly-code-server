# build gem5 stage
FROM ubuntu:focal AS gem5-builder

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

RUN \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y \ 
    build-essential \
    git \
    m4 \
    scons \
    zlib1g \
    zlib1g-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libprotoc-dev \
    libgoogle-perftools-dev \
    python3-dev \
    python3-six \
    python-is-python3 \
    libboost-all-dev \
    pkg-config && \
  echo "**** build gem5 ****" && \
  git clone https://github.com/lexesjan/gem5 && \
  cd gem5 && \
  scons build/ARM/gem5.fast -j 16

# build extension stage
FROM ubuntu:focal AS extension-builder

WORKDIR /tmp

RUN \
  echo "**** install node repo ****" && \
  apt-get update && \
  apt-get install -y \
    curl \
    gnupg && \
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo 'deb https://deb.nodesource.com/node_14.x focal main' \
    > /etc/apt/sources.list.d/nodesource.list && \
  curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
    > /etc/apt/sources.list.d/yarn.list && \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    nodejs \
    yarn && \
  echo "**** build cortex-debug extension ****" && \
  git clone https://github.com/lexesjan/cortex-debug && \
  cd ./cortex-debug && \
  npm install && \
  yes | npx vsce package && \
  cp cortex-debug-*.vsix .. && \
  cd .. && \
  echo "**** build cortex-debug-db-stm32f4 extension ****" && \
  git clone https://github.com/lexesjan/cortex-debug-db-stm32f4 && \
  cd ./cortex-debug-db-stm32f4 && \
  npm install && \
  yes | npx vsce package && \
  cp cortex-debug-dp-stm32f4-*.vsix ..

# install stage
FROM lscr.io/linuxserver/code-server

# add local files
COPY ./root /

COPY --from=gem5-builder /tmp/gem5/build/ARM/gem5.fast /usr/local/bin/
COPY --from=extension-builder /tmp/cortex-debug-*.vsix ./

RUN \
  echo "**** install vscode extensions ****" && \
  install-extension dan-c-underwood.arm && \
  install-extension cortex-debug-*.vsix && \
  install-extension cortex-debug-dp-stm32f4-*.vsix && \
  echo "**** install development dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    gcc-arm-none-eabi \
    gdb-multiarch \
    libgoogle-perftools4 \
    libprotobuf17 \
    make \
    psmisc && \
  echo "**** link binaries ****" && \
  ln -s /usr/bin/gdb-multiarch /usr/bin/arm-none-eabi-gdb && \
  echo "**** clean up ****" && \
  rm -rf \
    ./cortex-debug-dp-stm32f4-*.vsix