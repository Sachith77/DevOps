#!/bin/bash

# System Information Script

current_date=$(date)
current_host=$(hostname)
current_user=$(whoami)

echo "===== System Information ====="
echo "Current Date : $current_date"
echo "Hostname     : $current_host"
echo "Username     : $current_user"

echo ""
echo "===== Disk Usage ====="
df -h

read -p "Enter a name for the output directory: " dir_name
mkdir -p "$dir_name"
echo "Directory '$dir_name' created."

read -p "Enter a name for the output file (without extension): " file_name
output_file="$dir_name/$file_name.txt"
touch "$output_file"
echo "File '$output_file' created."

echo ""
echo "===== Running Processes ====="
ps -eo pid,ppid,user,%cpu,%mem,stat,start,time,comm

ps -eo pid,ppid,user,%cpu,%mem,stat,start,time,comm > "$output_file"
echo ""
echo "Running processes information has been saved to: $output_file"
