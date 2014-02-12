#!/bin/bash

#/opt/cloud9/bin/cloud9.sh -l 0.0.0.0 -w /var/lib/cloud9 -p 3000 >/opt/cloud9/log 2>&1 &
#/usr/local/bin/node /opt/cloud9/server.js -l 0.0.0.0 -w /var/lib/cloud9 -p 3000 >/opt/cloud9/log 2>&1 &
/usr/bin/node /opt/cloud9/server.js -l 0.0.0.0 -w /var/lib/cloud9 -p 3000
