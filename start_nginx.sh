#!/usr/bin/env bash
cd /code
sed s/BASE_URL\:\ \"[a-zA-Z0-9:\/]*\"/BASE_URL\:\ \"\$BASE_URL\"/g config.js > config.new.js && mv config.new.js config.js
envsubst '\$BASE_URL' < config.js > config.tmp.js && mv config.tmp.js config.js
echo "Starting Nginx"
nginx -g 'daemon off;'