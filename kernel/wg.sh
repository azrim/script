#!/bin/bash
#

# init
KERNEL_DIR=$PWD
WG=$HOME/wireguard
WGVER="1.0.20200520" #get latest tag from here: https://git.zx2c4.com/wireguard-linux-compat

# execute
mkdir $WG
cd $WG && wget https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-$WGVER.tar.xz
cd $KERNEL_DIR
rm -rf net/wireguard && mkdir net/wireguard
tar -C "net/wireguard" -xJf $WG/wireguard-linux-compat-$WGVER.tar.xz --strip-components=2 wireguard-linux-compat-$WGVER/src
git add net && git commit -am "net: wireguard: update wireguard to version $WGVER"

#END
