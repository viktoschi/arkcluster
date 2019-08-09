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

# Change IDs
groupmod -g $GROUP_ID steam
usermod -u $USER_ID steam

[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging

# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam

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
