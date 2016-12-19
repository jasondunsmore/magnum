#!/bin/sh -x

# make sure we pick up any modified unit files
systemctl daemon-reload

echo "starting services"
for service in kubelet; do
    echo "activating service $service"
    systemctl enable $service
    systemctl --no-block start $service
done
