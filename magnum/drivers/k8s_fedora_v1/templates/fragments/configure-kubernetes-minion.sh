#!/bin/sh

. /etc/sysconfig/heat-params

echo "configuring kubernetes (minion)"

CA_CERT_DATA=$(base64 -w 0 /srv/kubernetes/ca.crt)
CLIENT_CERT_DATA=$(base64 -w 0 /srv/kubernetes/client.crt)
CLIENT_KEY_DATA=$(base64 -w 0 /srv/kubernetes/client.key)

HOSTNAME=$(hostname)
KUBE_API_URL=https://$KUBE_API_PUBLIC_ADDRESS:$KUBE_API_PORT

cat > /etc/kubernetes/kubelet.conf <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $CA_CERT_DATA
    server: $KUBE_API_URL
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet-$HOSTNAME
  name: kubelet-$HOSTNAME@kubernetes
current-context: kubelet-$HOSTNAME@kubernetes
kind: Config
preferences: {}
users:
- name: kubelet-$HOSTNAME
  user:
    client-certificate-data: $CLIENT_CERT_DATA
    client-key-data: $CLIENT_KEY_DATA
EOF
