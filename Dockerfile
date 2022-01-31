FROM lscr.io/linuxserver/code-server

# add local files
COPY ./root /

RUN \
  echo "**** install vscode extensions ****" && \
  install-extension marus25.cortex-debug && \
  install-extension dan-c-underwood.arm && \
  git clone https://github.com/lexesjan/cortex-debug-db-stm32f4 && \
  cd ./cortex-debug-db-stm32f4 && \
  npm install && \
  yes | npx vsce package && \
  install-extension cortex-debug-dp-stm32f4-*.vsix && \
  cd .. && \
  echo "**** install development dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    gcc-arm-none-eabi \
    gdb-multiarch \
    make \
    wget && \
  ln -s /usr/bin/gdb-multiarch /usr/bin/arm-none-eabi-gdb && \
  curl https://api.github.com/repos/xpack-dev-tools/qemu-arm-xpack/releases/latest | \
    grep "browser_download_url" | \
    grep -Eo "https://[^\"]*" | \
    grep -m 1 "linux-x64" | \
    xargs wget -O - | \
    tar -xz && \
  mv xpack-qemu-arm* ~/.xpack-qemu-arm && \
  ln -s ~/.xpack-qemu-arm/bin/qemu-system-gnuarmeclipse /usr/bin/qemu-system-gnuarmeclipse && \
  echo "**** clean up ****" && \
  rm -rf ./cortex-debug-db-stm32f4