# https://github.com/phusion/baseimage-docker
FROM phusion/baseimage:latest-amd64

LABEL org.label-schema.maintainer="Richard Kuhnt <r15ch13+git@gmail.com>" \
      org.label-schema.description="Base ARK Cluster Image" \
      org.label-schema.url="https://github.com/r15ch13/arkcluster" \
      org.label-schema.vcs-url="https://github.com/r15ch13/arkcluster" \
      org.label-schema.schema-version="1.0.0-rc1"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Install dependencies and clean up
RUN apt-get update \
    && apt-get upgrade -y -o Dpkg::Options::="--force-confold" \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        curl \
        git \
        lib32gcc1 \
        libc6-i386 \
        lsof \
        perl-modules \
        tzdata \
        davfs2 \
        fuse \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create required directories
RUN mkdir -p /ark \
    mkdir -p /ark/log \
    mkdir -p /ark/backup \
    mkdir -p /ark/staging \
    mkdir -p /ark/default \
    mkdir -p /cluster

# Expose environment variables
ENV USER_ID=1000 \
    GROUP_ID=1000 \
    KILL_PROCESS_TIMEOUT=300 \
    KILL_ALL_PROCESSES_TIMEOUT=300

# Add steam user
RUN addgroup --gid $GROUP_ID steam \
    && adduser --system --uid $USER_ID --gid $GROUP_ID --shell /bin/bash steam \
    && usermod -a -G docker_env steam

# Install ark-server-tools
RUN git clone --single-branch --depth 1 https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools \
    && cd /home/steam/ark-server-tools/tools/ \
    && ./install.sh steam --bindir=/usr/bin

# Install steamdcmd
RUN mkdir -p /home/steam/steamcmd \
    && cd /home/steam/steamcmd \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
