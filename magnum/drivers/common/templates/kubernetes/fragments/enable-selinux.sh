#!/bin/sh -xe

# Create an selinux module to allow k8s cluster to create
semodule_dir=$(mktemp -d)
cleanup() {
    rm -rf $semodule_dir
}
trap cleanup EXIT
cat >> $semodule_dir/k8s_node.te <<EOF

module k8s_node 1.0;

require {
        type sshd_t;
        type init_t;
        type kernel_t;
        type chkpwd_t;
        type systemd_machined_t;
        type unconfined_t;
        class process { noatsecure rlimitinh siginh };
        class unix_stream_socket { read write };
}

#============= init_t ==============
allow init_t chkpwd_t:process { noatsecure rlimitinh siginh };
allow init_t kernel_t:unix_stream_socket { read write };
allow init_t systemd_machined_t:process { noatsecure rlimitinh };
allow init_t unconfined_t:process { rlimitinh siginh };

#============= sshd_t ==============
allow sshd_t chkpwd_t:process { noatsecure rlimitinh siginh };
EOF
checkmodule -M -m -o $semodule_dir/k8s_node.mod $semodule_dir/k8s_node.te
semodule_package -o $semodule_dir/k8s_node.pp -m $semodule_dir/k8s_node.mod
semodule -i $semodule_dir/k8s_node.pp

# Turn on SELinux enforcement
setenforce 1

# Turn on logging of AVC messages in /var/log/audit/audit.log
semodule -DB
