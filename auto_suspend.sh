#!/bin/bash

: "${AUTORANR_PROFILE=sd}" # change this to the name of the profile you want to use
: "${SUSPEND_TIME:=10}" # set a default timeout of 10 minutes

export DISPLAY=:0
STREAM=false

while true; do
  # Check which profile is loaded
  PROFILE=$(autorandr --current)

  # Check if "sd" profile is loaded
  if [[ $PROFILE == $AUTORANR_PROFILE ]]; then
    while pgrep steam >/dev/null; do
      SECONDS=0
      # we want to check if the profile is still loaded, if not, break out of the loop
      PROFILE=$(autorandr --current); if [[ $PROFILE != $AUTORANR_PROFILE ]]; then
        echo "The $AUTORANR_PROFILE profile is not currently loaded. Will not automatically suspend."
        break; fi
      # check if a stream is running, if not, start the timer
      while tail -2 /home/${USER}/.steam/steam/logs/streaming_log.txt | grep -q '>>> Stopped desktop stream' || STREAM=true; do
        if [[ $SECONDS -le 14 && $STREAM == false ]]; then 
          echo "No Remote Play Stream running, starting $SUSPEND_TIME minute timer to suspend PC"
        fi
        MINS=$((SECONDS / 60)); 
        if [[ $STREAM == false ]]; then
          # reset when resuming from sleep
          if [[ $MINS -gt $SUSPEND_TIME ]]; then break; fi
          echo "Suspending in $((SUSPEND_TIME - MINS)) minutes"
        else
          echo "Stream detected, resetting timer..."
          STREAM=false; SECONDS=0
        fi
        # if the timer is up, suspend the PC
        if [ "$MINS" -eq "$SUSPEND_TIME" ]; then
          echo "Suspending PC..."
          sudo systemctl suspend
        fi
        # we want to check if the profile is still loaded, if not, break out of the loop
        PROFILE=$(autorandr --current); if [[ $PROFILE != $AUTORANR_PROFILE ]]; then break; fi; sleep 10
      done; sleep 10
    done
  else
    echo "The $AUTORANR_PROFILE profile is not currently loaded. Will not automatically suspend."
  fi; sleep 15
done
