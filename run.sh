#!/usr/bin/env bash
source /etc/container_environment.sh

echo "###########################################################################"
echo "# Started  - `date`"
echo "# Server   - ${SESSION_NAME}"
echo "# Cluster  - ${CLUSTER_ID}"
echo "# User     - ${USER_ID}"
echo "# Group    - ${GROUP_ID}"
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

function stop {
    if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks)" ]; then
        echo "Creating Backup ..."
        arkmanager backup
    fi
    if [ ${WARNONSTOP} -eq 1 ]; then
        arkmanager stop --warn
    else
        arkmanager stop
    fi
    exit
}

# Change the USER_ID if needed
if [ ! "$(id -u steam)" -eq "$USER_ID" ]; then
    echo "Changing steam uid to $USER_ID."
    usermod -o -u "$USER_ID" steam ;
fi
# Change gid if needed
if [ ! "$(id -g steam)" -eq "$GROUP_ID" ]; then
    echo "Changing steam gid to $GROUP_ID."
    groupmod -o -g "$GROUP_ID" steam ;
fi

[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging

if [ -f /usr/share/zoneinfo/${TZ} ]; then
    echo "Setting timezone to ${TZ} ..."
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
fi

if [ ! -f /etc/cron.d/upgrade-tools ]; then
    echo "Adding update cronjob (${CRON_UPGRADE_TOOLS}) ..."
    echo "$CRON_UPGRADE_TOOLS root /bin/bash yes | arkmanager upgrade-tools >> /ark/log/arkmanager-upgrade.log 2>&1" > /etc/cron.d/upgrade-tools
fi

# We overwrite the default file each time
cp /home/steam/arkmanager-user.cfg /ark/default/arkmanager.cfg

# Copy default arkmanager.cfg if it doesn't exist
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager-user.cfg /ark/arkmanager.cfg
if [ ! -L /etc/arkmanager/instances/main.cfg ]; then
    rm /etc/arkmanager/instances/main.cfg
    ln -s /ark/arkmanager.cfg /etc/arkmanager/instances/main.cfg
fi

# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam
echo "###########################################################################"

if [ ! -d /ark/server  ] || [ ! -f /ark/server/version.txt ]; then
    echo "No game files found. Installing..."
    mkdir -p /ark/server/ShooterGame/Saved/SavedArks
    mkdir -p /ark/server/ShooterGame/Content/Mods
    mkdir -p /ark/server/ShooterGame/Binaries/Linux
    touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
    chown -R steam:steam /ark/server
    arkmanager install
else
    if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks/)" ]; then
        echo "Creating Backup ..."
        arkmanager backup
    fi
fi

echo "###########################################################################"
echo "Installing Mods ..."
arkmanager installmods

echo "###########################################################################"
echo "Launching ark server ..."
if [ ${UPDATEONSTART} -eq 1 ]; then
    arkmanager start
else
    arkmanager start -noautoupdate
fi

# Stop server in case of signal INT or TERM
echo "###########################################################################"
echo "Running ... (waiting for INT/TERM signal)"
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
