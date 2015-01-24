#!/bin/bash

oldpath=$(pwd)

usage() {
	echo "Usage: $0 <number-of-hosts>"
	echo " will create <number-of-hosts> lxd hosts"
	echo " will generate a certificate for those to share"
}

if [ $# -ne 1 ]; then
	usage
	exit 1
fi

GOPATH=$HOME/go
if [ ! -d ~/go/src/github.com/lxc/lxd ]; then
	echo "Please go get github.com/lxc/lxd"
	exit 1
fi

cd ~/go/src/github.com/lxc/lxd/lxc
# create client keys if we haven't already
./lxc list

virsh list --all | awk '/uvt-lxd/ { print $2 }' | while read line; do
	uvt-kvm destroy $line
	sleep 2
done

if [ $1 -lt 1 -o $1 -gt 10 ]; then
	echo "$i is not between 1 and 10"
	exit 1
fi
for i in $(seq 1 $1); do
	uvt-kvm create uvt-lxd-$i release=vivid arch=amd64 --run-script-once ${oldpath}/lxd.install
done

echo "Sleeping one minute for vms to set up"
sleep 60
echo "Proceeding"

for i in $(seq 1 $1); do
	./lxc remote remove uvt-lxd-$i
	uvt-kvm wait --insecure uvt-lxd-$i
	ip=`uvt-kvm ip uvt-lxd-$i`
	scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ~/.config/lxc/client.crt ubuntu@${ip}:
	uvt-kvm ssh --insecure uvt-lxd-$i -- "while [ ! -f /lxd.done ]; do sleep 5s; done"
	uvt-kvm ssh --insecure uvt-lxd-$i -- sudo mkdir /var/lib/lxd/clientcerts
	uvt-kvm ssh --insecure uvt-lxd-$i -- sudo cp client.crt /var/lib/lxd/clientcerts/$(hostname).crt
	uvt-kvm ssh --insecure uvt-lxd-$i -- sudo stop lxd
	uvt-kvm ssh --insecure uvt-lxd-$i -- sudo start lxd
	uvt-kvm ssh --insecure uvt-lxd-$i -- "while [ ! -f /var/lib/lxd/server.crt ]; do sleep 3s; done"
	scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ubuntu@${ip}:/var/lib/lxd/server.crt ~/.config/lxc/servercerts/uvt-lxd-$i.crt
	./lxc remote add uvt-lxd-$i ${ip}:8431
done
