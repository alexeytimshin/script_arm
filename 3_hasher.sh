#!/bin/bash

BUILDDIR="$PWD"
rootfs="$BUILDDIR/rootfs"
#packages="alt-os-release basesystem branding-alt-spserver-release common-licenses control dracut diffutils etcskel findutils gawk gzip libaudit1 libblkid libcap-ng libcap-utils libcrypt libgpm libmount libncursesw libpam0 libpasswdqc libshell libsmartcols libtcb libtic libudev1 libuuid nss_tcb openssh-clients-gostcrypto openssh-common-gostcrypto openssh-server-control-gostcrypto openssh-server-gostcrypto pam pam-config pam-config-control pam0_mktemp pam0_passwdqc pam0_tcb pam0_userpass passwdqc-control perl-base perl-parent rootfiles sed setarch shadow-convert shadow-utils tar tcb-utils termutils util-linux util-linux-control vim-minimal vitmp xz zstd acl agetty alt-gpgkeys alternatives altlinux-repos apt apt-conf-branch-gostcrypto bzip2 ca-certificates ca-trust chkconfig chrooted chrooted-resolv console-scripts console-vt-tools crontab-control crontabs dbus dbus-tools dmsetup dosfstools e2fsprogs fatresize file gdisk gettext glib2 glib2-locales glibc-gconv-modules glibc-locales glibc-nss glibc-utils gnupg groff-base hwclock info info-install interactivesystem iproute2 iputils kbd kbd-data kmod less libapt libargon2 libatm libbrotlicommon libbrotlidec libcom_err libcrypto1.1 libcryptsetup libdbus libdevmapper libe2fs libexpat libfdisk libffi7 libfreetype libfuse libgdbm libgnutls30 libgraphite2 libharfbuzz libhogweed6 libidn2 libiptables libjson-c5 libkeymap libkmod liblz4 libmagic libmnl libnetlink libnettle8 libnss-myhostname libnss-systemd libp11-kit libparted libpci libpcre2 libpipeline libpng16 libprocps libseccomp libss libstdc++6 libsystemd libtasn1 libunistring2 libzio login losetup lsblk man-db mingetty mount msulogin p11-kit-trust pam_systemd parted passwd pciids pciutils procps psmisc rpm-macros-alternatives sash service setproctitle startup stmpclean systemd systemd-analyze systemd-modules-common systemd-networkd systemd-sysctl-common systemd-sysvinit systemd-tmpfiles-common systemd-utils-filetriggers sysvinit-utils time tzdata udev vixie-cron which"
packages="apt basesystem dracut fdisk glibc-locales interactivesystem iproute2 net-tools NetworkManager openssh-server-gostcrypto systemd tzdata"
rpms="$BUILDDIR/contrib/*"

mkdir $rootfs
mkaptbox $rootfs
hsh-mkchroot $rootfs
hsh-initroot -v $rootfs --pkg-build-list=""
hsh-install -v $rootfs $packages
hsh-install -v $rootfs $rpms

