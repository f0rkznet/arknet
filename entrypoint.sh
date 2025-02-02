#!/bin/bash
SERVER_MAP=TheIsland_WP
QueryPort=${QueryPort:-27015}
Port=${Port:-7777}
RCONPort=${RCONPort:-27020}
MaxPlayers=${MaxPlayers:-70}
clusterid=${clusterid:-}
AltSaveDirectoryName=${AltSaveDirectoryName:-}

APPID=2430930
PROTON_VERSION=GE-Proton8-30
validate=false
STEAM_COMPAT_DATA_PATH=/compatdata/$APPID
STEAM_COMPAT_CLIENT_INSTALL_PATH=/opt/steamcmd
LAUNCH_COMMAND="${SERVER_MAP}?RCONEnabled=True?SessionName=${SessionName}?RCONPort=${RCONPort}?Port=${Port}?QueryPort=${QueryPort}?MaxPlayers=${MaxPlayers}?listen?ipaddress=0.0.0.0"
if [ -n "$AltSaveDirectoryName" ]; then
    LAUNCH_COMMAND="${LAUNCH_COMMAND}?AltSaveDirectoryName=${AltSaveDirectoryName}"
fi
if [ -n "$clusterid" ]; then
    LAUNCH_COMMAND="${LAUNCH_COMMAND} -clusterid=${clusterid}"
fi

timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

shutdown () {
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    echo "$(timestamp) INFO: Saving world..."
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Saveworld
    # Not clear if DoExit saves first so explicitly save then exit
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Broadcast Server Going down in 180 seconds
    echo "$(timestamp) INFO: Waiting 180 seconds before shutting down"
    sleep 80
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Broadcast Server Going down in 100 seconds
    sleep 20
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Broadcast Server Going down in 60 seconds
    sleep 50
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Broadcast Server Going down in 10 seconds
    sleep 10
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Broadcast Server Going down now
    echo "$(timestamp) INFO: Saving world..."
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" Saveworld
    rcon -a 127.0.0.1:${RCONPort} -p "${ServerAdminPassword}" DoExit

    # Server exit doesn't close pid for some reason, so lets check that the port is closed and then send SIGTERM to main pid
    while netstat -aln | grep -q $Port; do
        sleep 1
    done

    echo "$(timestamp) INFO: Goodbye"
    kill -15 $arknet_pid
}

function app_update () {
    mkdir -p /data
    /opt/steamcmd/steamcmd.sh +force_install_dir /data \
        +@sSteamCmdForcePlatformType windows \
        +login anonymous \
        +app_update $APPID $( [ "$validate" = true ] && echo "validate" ) \
        +quit
    mkdir -p $STEAM_COMPAT_DATA_PATH
}

function header () {
echo """
  ____________         __                          __   
_/ ____\   _  \_______|  | __________ ____   _____/  |_ 
\   __\/  /_\  \_  __ \  |/ /\___   //    \_/ __ \   __\\
 |  |  \  \_/   \  | \/    <  /    /|   |  \  ___/|  |  
 |__|   \_____  /__|  |__|_ \/_____ \___|  /\___  >__|  
              \/           \/      \/    \/     \/      
   _____         __                  __                 
  /  _  \_______|  | __ ____   _____/  |_               
 /  /_\  \_  __ \  |/ //    \_/ __ \   __\              
/    |    \  | \/    <|   |  \  ___/|  |                
\____|__  /__|  |__|_ \___|  /\___  >__|                
        \/           \/    \/     \/                    
"""
}

function run () {
    dbus-uuidgen --ensure=/etc/machine-id
    PROTON_LOG=1 STEAM_COMPAT_DATA_PATH=$STEAM_COMPAT_DATA_PATH STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_COMPAT_CLIENT_INSTALL_PATH /opt/proton/${PROTON_VERSION}/proton run /data/ShooterGame/Binaries/Win64/ArkAscendedServer.exe ${LAUNCH_COMMAND}
}

function render_templates () {
    echo "$(timestamp) INFO: Rendering config templates"
    mkdir -p /data/ShooterGame/Saved/Config/WindowsServer
    envtmpl /tmp/GameUserSettings.ini.tmpl > /data/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini
    envtmpl /tmp/Game.ini.tmpl > /data/ShooterGame/Saved/Config/WindowsServer/Game.ini
}

trap 'shutdown' TERM

app_update

render_templates

header

run &

arknet_pid=$!

tail -f /data/ShooterGame/Saved/Logs/ShooterGame.log &

wait $arknet_pid