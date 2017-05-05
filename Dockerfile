FROM centos:7
MAINTAINER boerngenschmidt

# Var for first config
ENV SESSIONNAME="Ark Docker" \
    SERVERMAP="TheIsland" \
    SERVERPASSWORD="" \
    ADMINPASSWORD="adminpassword" \
    NBPLAYERS=70 \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    GIT_TAG="v1.6.24" \
    SERVERPORT=27015 \
    STEAMPORT=7778 \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    UID=1000 \
    GID=1000

## Install dependencies
RUN yum -y install glibc.i686 libstdc++.i686 git lsof \
 && yum clean all \
# && sed -i.bkp -e \
#	's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
#	/etc/sudoers \
 && adduser \
    -u $UID \
    -s /bin/bash \
    -U \
    steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN chmod 777 /home/steam/run.sh \
 && chmod 777 /home/steam/user.sh \
 && git clone -b $GIT_TAG --single-branch --depth 1 https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools \
 && cd /home/steam/ark-server-tools/tools \
 && bash install.sh steam --bindir=/usr/bin \
 && mkdir /ark \
 && chown steam /ark && chmod 755 /ark \
 && mkdir /home/steam/steamcmd \
 && cd /home/steam/steamcmd \
 && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Define default config file in /etc/arkmanager
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

# Define default config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}
# Add UDP
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp

VOLUME  /ark

# Change the working directory to /arkd
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/user.sh"]
