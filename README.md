# lxd startup scripts

Quickly create a set of vms running lxd.

This is a first step to charming lxd.

## Environment

You need to have lxd installed on your utopic or vivid host (see lxd.install
for how to do it).  (Note when this is charmed then we will spin up an extra
vm to be the client, instead of using the user's host as the client)

You also need uvtool, which is used to spin up vms.

Given those, just do

./start 3

to fire up 3 vms which act as lxd hosts.  After this you can

	cd $GOPATH/src/github.com/lxc/lxd/lxc
	./lxc remote list
		uvt-lxd-1 <192.168.122.216:8431>
		uvt-lxd-2 <192.168.122.184:8431>
		uvt-lxd-3 <192.168.122.228:8431>
	./lxc create images:ubuntu uvt-lxd-3:v1
	./lxc list uvt-lxd-3:
		v1
	./lxc start uvt-lxd-3:v1
