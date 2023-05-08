#!/bin/bash

CONFIG_FILE=netmaker.env
# TODO make sure this doesnt break, parse `certbot certificates` if yes
CERT_DIR=/etc/letsencrypt/live/stun.$NM_DOMAIN/
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# get and check the config
if [ ! -f "$SCRIPT_DIR/$CONFIG_FILE" ]; then
	echo "Config file missing"
	exit 1
fi
source "$SCRIPT_DIR/$CONFIG_FILE"
if [[ -n "$NM_DOMAIN" || -n "$NM_EMAIL" ]]; then
	echo "Config not valid"
	exit 1
fi

echo "Setting up SSL certificates..."

# get the zerossl wrapper for certbot
wget -qO /root/zerossl-bot.sh "https://github.com/zerossl/zerossl-bot/raw/master/zerossl-bot.sh"
chmod +x /root/zerossl-bot.sh

# preserve the env state
RESTART_CADDY=false
if [ -n "$(docker ps | grep caddy)" ]; then
	echo "Caddy is running, stopping for now..."
	RESTART_CADDY=true
	docker-compose -f /root/docker-compose.yml stop caddy
fi

# request certs
./zerossl-bot.sh certonly --standalone \
	-m "$NM_EMAIL" \
	-d "stun.$NM_DOMAIN" \
	-d "broker.$NM_DOMAIN" \
	-d "dashboard.$NM_DOMAIN" \
	-d "turnapi.$NM_DOMAIN" \
	-d "netmaker-exporter.$NM_DOMAIN" \
	-d "grafana.$NM_DOMAIN" \
	-d "prometheus.$NM_DOMAIN"

# TODO fallback to letsencrypt

# check if successful
if [ ! -f "$CERT_DIR"/fullchain.pem ]; then
	echo "SSL certificates failed"
	exit 1
fi

# copy for mounting
cp "$CERT_DIR"/fullchain.pem /root
cp "$CERT_DIR"/privkey.pem /root

echo "SSL certificates ready"

# preserve the env state
if [ "$RESTART_CADDY" = true ]; then
	echo "Starting Caddy..."
	docker-compose -f /root/docker-compose.yml start caddy
fi
