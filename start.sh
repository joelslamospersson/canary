#!/bin/bash

BIN_PATH=${1:-"./canary"}
if [ -d "logs" ]
then
	echo -e "\e[01;32m Starting server \e[0m"
else
	mkdir -p logs
fi

if [ ! -f "config.lua" ]; then
	echo -e "\e[01;33m config.lua file not found, new file will be created \e[0m"
	cp config.lua.dist config.lua && ./docker/config.sh --env docker/.env
fi

ulimit -c unlimited
set -o pipefail

while true; do
	sleep 2
	echo -e "\e[01;32m Starting server... \e[0m"
	
	# Run the server and capture exit code properly
	# Use PIPEFAIL to ensure we get the exit code of the first command in the pipe
	set -o pipefail
	"$BIN_PATH" 2>&1 | awk '{ print strftime("%F %T - "), $0; fflush(); }' | tee "logs/$(date +"%F %H-%M-%S.log")"
	SERVER_EXIT_CODE=$?
	
	# Check if server exited normally (code 0) or crashed
	if [ $SERVER_EXIT_CODE -eq 0 ]; then
		echo -e "\e[01;33m Server exited normally (exit code 0). Waiting 30 seconds before restart... \e[0m"
		sleep 30
	else
		echo -e "\e[01;31m Server crashed with exit code $SERVER_EXIT_CODE. Restarting in 5 seconds... \e[0m"
		echo -e "\e[01;31m Press 'q' and Enter to stop the restart loop... \e[0m"
		sleep 5
	fi
	
	# Check for user input to stop
	read -t 1 -N 1 -r input
	if [[ "$input" == "q" ]]; then
		echo -e "\e[01;31m Stopping server restart loop... \e[0m"
		break
	fi
done
