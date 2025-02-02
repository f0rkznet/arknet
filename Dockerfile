FROM debian:12-slim

ARG ENVTEMPL_VERSION=0.3.0
ARG RCON_VERSION=0.10.3
ARG PROTON_VERSION=GE-Proton8-30

RUN sed -i 's#^Components: .*#Components: main non-free contrib#g' /etc/apt/sources.list.d/debian.sources \
    && dpkg --add-architecture i386

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -yq && \
    apt install -y --no-install-recommends \
        ca-certificates \
        wget \
        locales \
        lib32gcc-s1 \
        procps \
        winbind \
        dbus \
        libfreetype6 \
        net-tools

ADD --chown=root:root https://github.com/williambailey/go-envtmpl/releases/download/v${ENVTEMPL_VERSION}/envtmpl_${ENVTEMPL_VERSION}_linux_amd64.tar.gz /tmp/envtmpl.tar.gz
RUN tar zxfv /tmp/envtmpl.tar.gz -C /tmp --no-same-owner
RUN cp /tmp/envtmpl_${ENVTEMPL_VERSION}_linux_amd64/envtmpl /usr/local/bin && rm -rf /tmp/envtmpl*

# Install gorcon
ADD --chown=root:root https://github.com/gorcon/rcon-cli/releases/download/v${RCON_VERSION}/rcon-${RCON_VERSION}-amd64_linux.tar.gz /tmp
RUN tar zxfv /tmp/rcon-${RCON_VERSION}-amd64_linux.tar.gz \
        && rm -f rcon-${RCON_VERSION}-amd64_linux.tar.gz \
        && mv rcon-${RCON_VERSION}-amd64_linux/rcon /usr/local/bin \
        && rm -rf ./rcon-${RCON_VERSION}-amd64_linux

ADD --chown=root:root https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz /tmp
RUN mkdir /opt/steamcmd && tar zxfv /tmp/steamcmd_linux.tar.gz -C /opt/steamcmd && rm /tmp/steamcmd_linux.tar.gz

ADD --chown=root:root https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz /tmp/proton.tar.gz
RUN mkdir /opt/proton && tar zxfv /tmp/proton.tar.gz -C /opt/proton && rm /tmp/proton.tar.gz && ln -s /opt/proton/${PROTON_VERSION}/proton /usr/local/bin/proton

COPY templates/Game.ini.tmpl /tmp/Game.ini.tmpl
COPY templates/GameUserSettings.ini.tmpl /tmp/GameUserSettings.ini.tmpl

RUN /opt/steamcmd/steamcmd.sh +quit && mkdir -p /root/.steam/sdk32 && \
        ln -s /opt/steamcmd/linux32/steamclient.so /root/.steam/sdk32/steamclient.so && \
        mkdir -p /root/.steam/sdk64 && \
        ln -s /opt/steamcmd/linux64/steamclient.so /root/.steam/sdk64/steamclient.so

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 7777/udp 7778/udp 27015/udp 27020/tcp

ENTRYPOINT [ "/entrypoint.sh" ]