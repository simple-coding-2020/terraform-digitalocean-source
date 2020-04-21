#!/bin/bash

apt-get update -y
apt-get install git -y
apt-get install nodejs -y
apt-get install npm -y

npm install pm2 -g

git clone https://github.com/simple-coding-2020/terraform-digitalocean-app app
cd app
npm install
pm2 start index.js
