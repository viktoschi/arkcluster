FROM i386/ubuntu:16.04
MAINTAINER TuRzAm

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
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y sudo curl lsof git ssh bzip2 \
 && sed -i.bkp -e \
	's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
	/etc/sudoers \
 && apt-get clean \
 && apt-get purge \
 && groupadd -g $GID steam \
 && useradd \
    --gid $GID \
    --uid $UID \
    --groups sudo \
	--shell /bin/bash \
	steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN touch /root/.bash_profile \
 && chmod 777 /home/steam/run.sh \
 && chmod 777 /home/steam/user.sh \
 && mkdir /ark \
 && git clone -b $GIT_TAG --single-branch --depth 1 https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools \
 && cd /home/steam/ark-server-tools/tools \
 && chmod +x install.sh \
 && ./install.sh steam \
 && ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager \
 && chown steam -R /ark && chmod 755 -R /ark \
 && mkdir /home/steam/steamcmd \
 && cd /home/steam/steamcmd \
 && curl http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar -vxz

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
