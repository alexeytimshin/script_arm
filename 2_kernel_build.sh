#!/bin/bash

BUILDDIR="$PWD"
GIT_URL="https://github.com/raspberrypi/linux"
BRANCH="rpi-6.6.y"
KERNEL="kernel8"
ARCH="arm64"
CONFIG_ARM="bcm2711_defconfig"
MODULES_DIR="$BUILDDIR/modules"
LINUX_SOURCE="linux"

# установка пакетов для сборки
apt-get update
apt-get install -y bc git bison flex libssl libssl-devel make

# клонируем ветку репозитория
if [ -n "$BRANCH" ]; then
git clone --depth=1 --branch $BRANCH $GIT_URL $LINUX_SOURCE
else
git clone --depth=1 $GIT_URL
fi

# сборка ядра
cd $LINUX_SOURCE
make KERNEL=$KERNEL ARCH=$ARCH $CONFIG_ARM
sed -i 's/^CONFIG_LOCALVERSION.*/CONFIG_LOCALVERSION="-udv-ifw"/' .config
make -j$(nproc) KERNEL=$KERNEL ARCH=$ARCH Image modules dtbs

# возвращение в исходную директорию
cd $BUILDDIR

