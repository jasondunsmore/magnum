#!/bin/sh -x

. /etc/sysconfig/heat-params

echo "configuring kubernetes (master)"

mkdir -p /etc/kubernetes/manifests

cat > /etc/kubernetes/manifests/kube-apiserver.json << EOF
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "kube-apiserver",
    "namespace": "kube-system",
    "creationTimestamp": null,
    "labels": {
      "component": "kube-apiserver",
      "tier": "control-plane"
    }
  },
  "spec": {
    "volumes": [
      {
        "name": "certs",
        "hostPath": {
          "path": "/etc/ssl/certs"
        }
      },
      {
        "name": "pki",
        "hostPath": {
          "path": "/etc/kubernetes"
        }
      }
    ],
    "containers": [
      {
        "name": "kube-apiserver",
        "image": "gcr.io/google_containers/kube-apiserver-amd64:${KUBE_VERSION}",
        "command": [
          "kube-apiserver",
          "--v=2",
          "--insecure-bind-address=127.0.0.1",
          "--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota",
          "--service-cluster-ip-range=$PORTAL_NETWORK_CIDR",
          "--service-account-key-file=/etc/kubernetes/pki/service_account_key.pub",
          "--client-ca-file=/etc/kubernetes/pki/ca.crt",
          "--tls-cert-file=/etc/kubernetes/pki/server.crt",
          "--tls-private-key-file=/etc/kubernetes/pki/server.key",
          "--token-auth-file=/etc/kubernetes/pki/tokens.csv",
          "--secure-port=6443",
          "--allow-privileged",
          "--advertise-address=$KUBE_NODE_IP",
          "--etcd-servers=http://127.0.0.1:2379"
        ],
        "resources": {
          "requests": {
            "cpu": "250m"
          }
        },
        "volumeMounts": [
          {
            "name": "certs",
            "mountPath": "/etc/ssl/certs"
          },
          {
            "name": "pki",
            "readOnly": true,
            "mountPath": "/etc/kubernetes/"
          }
        ],
        "livenessProbe": {
          "httpGet": {
            "path": "/healthz",
            "port": 8080,
            "host": "127.0.0.1"
          },
          "initialDelaySeconds": 15,
          "timeoutSeconds": 15,
          "failureThreshold": 8
        }
      }
    ],
    "hostNetwork": true
  },
  "status": {}
}
EOF

cat > /etc/kubernetes/manifests/kube-controller-manager.json << EOF
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "kube-controller-manager",
    "namespace": "kube-system",
    "creationTimestamp": null,
    "labels": {
      "component": "kube-controller-manager",
      "tier": "control-plane"
    }
  },
  "spec": {
    "volumes": [
      {
        "name": "certs",
        "hostPath": {
          "path": "/etc/ssl/certs"
        }
      },
      {
        "name": "pki",
        "hostPath": {
          "path": "/etc/kubernetes"
        }
      }
    ],
    "containers": [
      {
        "name": "kube-controller-manager",
        "image": "gcr.io/google_containers/kube-controller-manager-amd64:${KUBE_VERSION}",
        "command": [
          "kube-controller-manager",
          "--v=2",
          "--address=127.0.0.1",
          "--leader-elect",
          "--master=127.0.0.1:8080",
          "--cluster-name=kubernetes",
          "--root-ca-file=/etc/kubernetes/pki/ca.crt",
          "--service-account-private-key-file=/etc/kubernetes/pki/service_account_key",
          "--insecure-experimental-approve-all-kubelet-csrs-for-group=system:kubelet-bootstrap",
          "--allocate-node-cidrs=true",
          "--pod-eviction-timeout=1m",
          "--cluster-cidr=$FLANNEL_NETWORK_CIDR"
        ],
        "resources": {
          "requests": {
            "cpu": "200m"
          }
        },
        "volumeMounts": [
          {
            "name": "certs",
            "mountPath": "/etc/ssl/certs"
          },
          {
            "name": "pki",
            "readOnly": true,
            "mountPath": "/etc/kubernetes/"
          }
        ],
        "livenessProbe": {
          "httpGet": {
            "path": "/healthz",
            "port": 10252,
            "host": "127.0.0.1"
          },
          "initialDelaySeconds": 15,
          "timeoutSeconds": 15,
          "failureThreshold": 8
        }
      }
    ],
    "hostNetwork": true
  },
  "status": {}
}
EOF

cat > /etc/kubernetes/manifests/kube-scheduler.json << EOF
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "kube-scheduler",
    "namespace": "kube-system",
    "creationTimestamp": null,
    "labels": {
      "component": "kube-scheduler",
      "tier": "control-plane"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "kube-scheduler",
        "image": "gcr.io/google_containers/kube-scheduler-amd64:${KUBE_VERSION}",
        "command": [
          "kube-scheduler",
          "--v=2",
          "--address=127.0.0.1",
          "--leader-elect",
          "--master=127.0.0.1:8080"
        ],
        "resources": {
          "requests": {
            "cpu": "100m"
          }
        },
        "livenessProbe": {
          "httpGet": {
            "path": "/healthz",
            "port": 10251,
            "host": "127.0.0.1"
          },
          "initialDelaySeconds": 15,
          "timeoutSeconds": 15,
          "failureThreshold": 8
        }
      }
    ],
    "hostNetwork": true
  },
  "status": {}
}
EOF

cat > /usr/sbin/kubectl << 'EOF'
#!/bin/bash
kubelet_id=$(docker ps --filter name=kubelet --format "{{.ID}}")
docker exec "$kubelet_id" /kubectl $@
EOF
chmod +x /usr/sbin/kubectl
