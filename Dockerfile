from lscr.io/linuxserver/code-server

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
  echo "**** clean up ****" && \
  rm -rf ./cortex-debug-db-stm32f4