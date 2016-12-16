#!/bin/sh

. /etc/sysconfig/heat-params

if [ -n "${INSECURE_REGISTRY_URL}" ]; then
    HYPERKUBE_IMAGE="${INSECURE_REGISTRY_URL}/google_containers/hyperkube:${KUBE_VERSION}"
else
    HYPERKUBE_IMAGE="gcr.io/google_containers/hyperkube:${KUBE_VERSION}"
fi

KUBELET_SERVICE=/etc/systemd/system/kubelet.service

mkdir /var/lib/kubelet
cat >> $KUBELET_SERVICE <<'EOF'
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStartPre=-/bin/mkdir -p /var/lib/kubelet
ExecStartPre=/bin/bash -c '/usr/bin/mountpoint -q /var/lib/kubelet || /usr/bin/mount --bind /var/lib/kubelet /var/lib/kubelet'
ExecStartPre=/usr/bin/mount --make-shared /var/lib/kubelet
ExecStart=/usr/bin/docker run --name kubelet \
            -v /:/rootfs:ro \
            -v /sys:/sys \
            -v /var/run:/var/run \
            -v /run:/run \
            -v /var/lib/docker:/var/lib/docker \
            -v /var/lib/kubelet:/var/lib/kubelet:shared \
            -v /var/log/containers:/var/log/containers \
            -v /srv/kubernetes:/srv/kubernetes \
            -v /etc/kubernetes:/etc/kubernetes \
            -v /etc/ssl/certs:/etc/ssl/certs \
            --net=host \
            --pid=host \
            --privileged \
EOF
cat >> $KUBELET_SERVICE <<EOF
            $HYPERKUBE_IMAGE /hyperkube kubelet \\
EOF
cat >> $KUBELET_SERVICE <<'EOF'
            --config=/etc/kubernetes/manifests \
            $KUBE_LOGTOSTDERR \
            $KUBE_LOG_LEVEL \
            $KUBELET_API_SERVER \
            $KUBELET_ADDRESS \
            $KUBELET_PORT \
            $KUBELET_HOSTNAME \
            $KUBE_ALLOW_PRIV \
            $KUBELET_ARGS
ExecStop=/usr/bin/docker stop kubelet
Restart=always

[Install]
WantedBy=multi-user.target

EOF

chown root:root $KUBELET_SERVICE
chmod 0644 $KUBELET_SERVICE

