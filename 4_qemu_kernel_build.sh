#!/bin/bash

BUILDDIR="$PWD"
GIT_URL="https://github.com/raspberrypi/linux"
BRANCH="rpi-6.6.y"
KERNE="kernel8"
ARCH="arm64"
CONFIG_QEMU="defconfig"
QEMU_LINUX_SOURCE=linux_qemu

# клонируем ветку
if [ -n "$BRANCH" ]; then
git clone --depth=1 --branch $BRANCH $GIT_URL $QEMU_LINUX_SOURCE
else
git clone --depth=1 $GIT_URL
fi

# очищаем от cборки под железку
cd $QEMU_LINUX_SOURCE

#сборка ядра под QEMU
make KERNEL=$KERNEL ARCH=$ARCH $CONFIG_QEMU
sed -i 's/^CONFIG_LOCALVERSION_AUTO.*/CONFIG_LOCALVERSION_AUTO=n/' .config
sed -i 's/^CONFIG_LOCALVERSION="".*/CONFIG_LOCALVERSION="-udv-ifw"/' .config
make -j$(nproc) KERNEL=$KERNEL ARCH=$ARCH Image
