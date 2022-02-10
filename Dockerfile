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

# download binaries stage
FROM ubuntu:focal AS binary-downloader

WORKDIR /tmp

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    curl \
    wget && \
  echo "**** download binaries ****" && \
  curl https://api.github.com/repos/xpack-dev-tools/qemu-arm-xpack/releases/latest | \
    grep "browser_download_url" | \
    grep -Eo "https://[^\"]*" | \
    grep -m 1 "linux-x64" | \
    xargs wget -O - | \
    tar -xz && \
  mv ./xpack-qemu-arm* ./xpack-qemu-arm

# install stage
FROM lscr.io/linuxserver/code-server

# add local files
COPY ./root /

COPY --from=gem5-builder /tmp/gem5/build/ARM/gem5.fast /usr/local/bin/
COPY --from=extension-builder /tmp/cortex-debug-*.vsix ./
COPY --from=binary-downloader /tmp/xpack-qemu-arm/ /opt/xpack-qemu-arm/

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
    libprotobuf17 \
    make \
    psmisc && \
  echo "**** link binaries ****" && \
  ln -s /opt/xpack-qemu-arm/bin/qemu-system-gnuarmeclipse /usr/local/bin/qemu-system-gnuarmeclipse && \
  ln -s /usr/bin/gdb-multiarch /usr/bin/arm-none-eabi-gdb && \
  echo "**** clean up ****" && \
  rm -rf \
    ./cortex-debug-dp-stm32f4-*.vsix