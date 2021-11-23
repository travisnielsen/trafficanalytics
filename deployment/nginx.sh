#!/bin/sh
sudo apt update && sudo apt -y install nginx
sudo ufw allow 'nginx http'
sudo ufw reload