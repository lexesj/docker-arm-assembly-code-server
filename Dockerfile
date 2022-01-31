# download binaries stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:focal AS binary-downloader

WORKDIR /tmp

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    wget && \
  echo "**** download binaries ****" && \
  curl https://api.github.com/repos/xpack-dev-tools/qemu-arm-xpack/releases/latest | \
    grep "browser_download_url" | \
    grep -Eo "https://[^\"]*" | \
    grep -m 1 "linux-x64" | \
    xargs wget -O - | \
    tar -xz && \
  mv ./xpack-qemu-arm* ./xpack-qemu-arm

# build extension stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:focal AS extension-builder

WORKDIR /tmp

RUN \
  echo "**** install node repo ****" && \
  apt-get update && \
  apt-get install -y \
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

COPY --from=binary-downloader /tmp/xpack-qemu-arm/ ./xpack-qemu-arm/
COPY --from=extension-builder /tmp/cortex-debug-dp-stm32f4-*.vsix ./

RUN \
  echo "**** install vscode extensions ****" && \
  install-extension marus25.cortex-debug && \
  install-extension dan-c-underwood.arm && \
  install-extension cortex-debug-dp-stm32f4-*.vsix && \
  echo "**** install development dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    gcc-arm-none-eabi \
    gdb-multiarch \
    make && \
  echo "**** link binaries ****" && \
  mv xpack-qemu-arm ~/.xpack-qemu-arm && \
  ln -s ~/.xpack-qemu-arm/bin/qemu-system-gnuarmeclipse /usr/bin/qemu-system-gnuarmeclipse && \
  ln -s /usr/bin/gdb-multiarch /usr/bin/arm-none-eabi-gdb && \
  echo "**** clean up ****" && \
  rm -rf \
    ./cortex-debug-dp-stm32f4-*.vsix 