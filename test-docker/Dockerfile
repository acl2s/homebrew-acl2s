FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential procps curl file git sudo openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/* # remove cached apt files

RUN groupadd linuxbrew && \
    useradd -rm -d /home/linuxbrew -s /bin/bash -g linuxbrew -u 1002 linuxbrew && \
    chmod -R g+rwx /home/linuxbrew

ARG USERNAME=cs2800
ARG PASSWORD=cs2800
RUN groupadd ${USERNAME} && \
    useradd -rm -d /home/${USERNAME} -s /bin/bash -g ${USERNAME} -u 1001 ${USERNAME} -p "$(openssl passwd -1 ${PASSWORD})" && \
    echo "[user]\ndefault=${USERNAME}\n[interop]\nappendWindowsPath=true" >> /etc/wsl.conf && \
    usermod -aG linuxbrew ${USERNAME} && \
    usermod -aG sudo ${USERNAME} && \
    echo '%sudo ALL=(ALL) ALL' >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

RUN brew install lz4 xz zlib zstd sbcl
RUN brew tap --force homebrew/core

RUN brew tap acl2s/acl2s
COPY Formula/acl2s.rb /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/acl2s/homebrew-acl2s/Formula/acl2s.rb
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_INSTALL_FROM_API=1
ENV HOMEBREW_VERBOSE=1
RUN brew install --build-from-source acl2s
