#!/bin/bash

# see https://ddulic.dev/steam-remote-play-with-linux-host for more information

function zwarning () {
  zenity --warning \
    --title="Manage PC" \
    --text="$1" \
    --width 500 \
    --height 100
  sleep 2
}

if [[ -z "${IP}" || -z "${MAC}" || -z "${USER}" ]]; then
  zwarning "Startup Check Failed. Please set the USER, IP &amp; MAC in the launch options\!"
  exit 1
fi

: "${TIMEOUT:=90}" # set a default timeout of 90 seconds
SSH_CONN="ssh -o ConnectTimeout=$TIMEOUT ${USER}@${IP}"

function zinfo() {
  zenity --info \
        --title="Manage PC" \
        --text="$1" \
        --timeout=2 \
        --width 500 \
        --height 100
  sleep 2
}

function zquestion() {
  zenity --question \
  --text="$1" \
  --width 500 \
  --height 100
}

function zprogress() {
  zenity --progress \
    --title="Manage PC" \
    --text="$1" \
    --no-cancel \
    --pulsate \
    --auto-close \
    --width 500 \
    --height 100
}

if zquestion "Wake PC / Set SD Resolution?"; then
  echo -e $(echo $(printf 'f%.0s' {1..12}; printf "$(echo $MAC | sed 's/://g')%.0s" {1..16}) | sed -e 's/../\\x&/g') | socat - UDP-DATAGRAM:255.255.255.255:4000,broadcast
  until ${SSH_CONN} 'export DISPLAY=:0; autorandr sd'; do sleep 2; done | zprogress "Waking up PC..."
  zinfo "PC Resolution set to SD\!"; sleep 1
  # unless the pc has just been started, restart steam
  if [ $(${SSH_CONN} "awk '{print \$1/1}' /proc/uptime") -gt 60 ]; then
    until ${SSH_CONN} 'steam -shutdown'; do
      sleep 2; done | zprogress "Restarting Steam..."
    # wait until all steam processes are gone
    while ${SSH_CONN} 'pgrep steam > /dev/null'; do
      sleep 2; done | zprogress "Restarting Steam..."
    # start steam in the background in screen
    until ${SSH_CONN} "screen -dmS steam bash -c 'export DISPLAY=:0; /usr/bin/steam-runtime -silent'"; do
      sleep 2; done | zprogress "Restarting Steam..."
    # wait for at least 4 steam processes to be up
    while [ $(${SSH_CONN} 'pgrep -c steam') -lt 4 ]; do sleep 2; done | zprogress "Restarting Steam..."
    zinfo "Steam Restarted\!"; sleep 1
  fi
else
  if zquestion "Sleep PC?"; then
    if ${SSH_CONN} 'sudo systemctl suspend'; then
      zinfo "Suspend command sent\!"; sleep 2
    fi
  else
    if zquestion "Shutdown PC?"; then
      if ${SSH_CONN} 'sudo systemctl poweroff'; then
        zinfo "Poweroff command sent\!"; sleep 2
      fi
    fi
  fi
fi
