#!/bin/bash

BUILDDIR="$PWD"
rootfs="rootfs"
apt update
apt install qemu-system-common binfmt-support qemu-efi-aarch64 debootstrap qemu-user-static
debootstrap --foreign --arch=arm64 bookworm $rootfs https://deb.debian.org/debian
chroot $rootfs sh -c "debootstrap/debootstrap --second-stage"
