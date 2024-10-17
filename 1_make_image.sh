#!/bin/bash

BUILDDIR="$PWD"
FILENAME="udv_ifw.img"
MOUNTPOINT="mnt"
GIT_FIRMWARE="https://github.com/raspberrypi/firmware.git"
FIRMWARE_DIR="$BUILDDIR/firmware"
MODULES_DIR="$BUILDDIR/modules"
CHROOT_DIR="$BUILDDIR/rootfs/chroot"
LINUX_SOURCE="$BUILDDIR/linux"
QEMU_LINUX_SOURCE="$BUILDDIR/linux_qemu"
ROOT_PASSWORD=P@ssw0rd
ARCH=arm64

# Формируем образ(размер сектора 512 байт, размер образа 1 ГБ)
dd if=/dev/zero of=$FILENAME bs=512 count=3000000
DEVLOOP=$(losetup --show -fP $FILENAME)
parted -s -a optimal -- ${DEVLOOP} mktable msdos

# Разбиваем диск на разделы и форматируем
parted -s -a optimal -- ${DEVLOOP} mkpart primary fat32 0% 256MB
parted -s -a optimal -- ${DEVLOOP} mkpart primary ext4 256MB 100%
parted -s -a optimal -- ${DEVLOOP} set 1 lba on
mkfs -t vfat ${DEVLOOP}p1
mkfs -t ext4 ${DEVLOOP}p2

# выносим PARTUUID в отдельные переменные
PARTUUID_BOOTFS=$(blkid ${DEVLOOP}p1 | awk '{print $6}' | sed 's/\"//g')
PARTUUID_ROOTFS=$(blkid ${DEVLOOP}p2 | awk '{print $5}' | sed 's/\"//g')

# Монтируем первый раздел
mkdir $BUILDDIR/$MOUNTPOINT
mount ${DEVLOOP}p1 $MOUNTPOINT

#загружаем файлы загрузчика в первый раздел
git clone --depth=1 $GIT_FIRMWARE
cp $FIRMWARE_DIR/boot/start*.elf $MOUNTPOINT
cp $FIRMWARE_DIR/boot/fixup*.dat $MOUNTPOINT
mkdir $BUILDDIR/${MOUNTPOINT}/overlays

#Создаем файлы cmdline и config
touch $BUILDDIR/${MOUNTPOINT}/cmdline.txt
touch $BUILDDIR/${MOUNTPOINT}/config.txt

#cmdline.txt
echo "console=serial0,115200 console=tty1 root=$PARTUUID_ROOTFS rootfstype=ext4 fsck.repair=yes rootwait quiet" > ${MOUNTPOINT}/cmdline.txt

#config.txt
echo "dtparam=audio=on
camera_auto_detect=1
display_auto_detect=1
auto_initramfs=1
dtoverlay=vc4-kms-v3d
max_framebuffers=2
disable_fw_kms_setup=1
arm_64bit=1
disable_overscan=1
arm_boost=1

[cm4]
otg_mode=1

[cm5]
dtoverlay=dwc2,dr_mode=host

[all]" > ${MOUNTPOINT}/config.txt

if [ ! -f "$LINUX_SOURCE/arch/$ARCH/boot/Image" ]; then
#вызов скрипта сборки ядра
bash $BUILDDIR/2_kernel_build.sh
fi

# копируем собранный образ ядра, dtb, модули
cp $LINUX_SOURCE/arch/$ARCH/boot/Image ${MOUNTPOINT}/kernel8.img
cp $LINUX_SOURCE/arch/$ARCH/boot/dts/broadcom/*.dtb ${MOUNTPOINT}
cp $LINUX_SOURCE/arch/$ARCH/boot/dts/overlays/*.dtb* ${MOUNTPOINT}/overlays/

# установим модули в отдельную директорию
cd $LINUX_SOURCE
#sudo env PATH=$PATH 
make -j$(nproc) ARCH=$ARCH INSTALL_MOD_PATH=$MODULES_DIR modules_install
KERNEL_VERSION=$(ls $MODULES_DIR/lib/modules/)

#размонтируем первый раздел
umount $BUILDDIR/$MOUNTPOINT
cd $BUILDDIR

#вызов скрипта сборки образа через hasher
sudo -u builder bash $BUILDDIR/3_hasher.sh

#сборка rootfs в архив
cd $CHROOT_DIR
tar cvf $BUILDDIR/rootfs.tar --no-same-owner *
cd $BUILDDIR

#монтируем второй раздел
mount ${DEVLOOP}p2 $MOUNTPOINT

# запись rootfs на второй раздел
tar -C $MOUNTPOINT --no-same-owner -xf rootfs.tar
cp -r $MODULES_DIR/lib/modules/$KERNEL_VERSION $MOUNTPOINT/lib/modules/
chroot "$MOUNTPOINT" sh -c "mkdir /boot/firmware"
chroot "$MOUNTPOINT" sh -c "echo '$PARTUUID_BOOTFS /boot/firmware   vfat    defaults    0 0' >> /etc/fstab"
chroot "$MOUNTPOINT" sh -c "echo '$PARTUUID_ROOTFS /   ext4    defaults    1 1' >> /etc/fstab"
chroot "$MOUNTPOINT" sh -c "echo 'root:$ROOT_PASSWORD' | chpasswd"
chroot "$MOUNTPOINT" sh -c "dracut --kver $KERNEL_VERSION /boot/initramfs8"
mv $MOUNTPOINT/boot/initramfs8 $BUILDDIR

#размонтируем второй раздел
umount $BUILDDIR/$MOUNTPOINT

#монтируем первый раздел для загрузки initramfs
mount ${DEVLOOP}p1 $MOUNTPOINT
mv initramfs8 $MOUNTPOINT
umount $BUILDDIR/$MOUNTPOINT
parted -s -a optimal -- ${DEVLOOP} set 1 lba on

#размонтируем образ
losetup -d ${DEVLOOP}

if [ ! -f "$QEMU_LINUX_SOURCE/arch/$ARCH/boot/Image" ]; then
#вызов скрипта сборки образа под qemu
bash $BUILDDIR/4_qemu_kernel_build.sh
fi

#копируем ядро под эмуляцию
cp $QEMU_LINUX_SOURCE/arch/$ARCH/boot/Image $BUILDDIR/kernelQEMU

#формируем скрипт запуска QEMU
echo "qemu-system-aarch64 \\
-nographic \\
-machine virt \\
-cpu cortex-a72 \\
-smp 6 -m 2G \\
-kernel kernelQEMU \\
-append \"root=/dev/vda2 rootfstype=ext4 rw panic=0 console=ttyAMA0 init=/sbin/systemd\" \\
-drive format=raw,file=udv_ifw.img,if=none,id=hd0,cache=writeback \\
-device virtio-blk,drive=hd0,bootindex=0" > QEMU_launcher.sh
chmod +x QEMU_launcher.sh

#clean
#rm -r $BUILDDIR/firmware
rm -r $MODULES_DIR
rm -r $BUILDDIR/rootfs.tar
rm -r $MOUNTPOINT
rm -r $BUILDDIR/rootfs
#rm -r $BUILDDIR/linux
#rm -r $BUILDDIR/$QEMU_LINUX_SOURCE