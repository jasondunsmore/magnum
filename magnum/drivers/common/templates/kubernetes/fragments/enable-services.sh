#!/bin/sh

# make sure we pick up any modified unit files
systemctl daemon-reload

for service in $SERVICES; do
    echo "activating service $service"
    systemctl enable $service
    systemctl --no-block start $service
done
