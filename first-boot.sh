#!/bin/sh

custom_banner(){
  imei=$(uqmi -d /dev/cdc-wdm0 --get-imei)
  provider=$(uqmi -d /dev/cdc-wdm0 --get-serving-system | grep plmn_description | tr -d '\t"plmn_description": ' | tr -d ',')
  mac=$(ifconfig | grep eth0 | tr -d 'eth Link encap Ethernet  HWaddr' )
  echo "$DISTRIB_DESCRIPTION" >> /etc/banner
  echo "IMEI=$imei"  "MAC=${mac: -17}"  "PROVIDER=$provider" >> /etc/banner
  echo "---------------------------------------------------" >> /etc/banner
}


extroot_config(){
  echo $'#\n#\n#\nConfiguring External Memory'
  # Copy cron for next reboot
  cp /srv/crons/first-boot-cron /etc/crontabs/root

  # Install the packages needed to configure extroot
  opkg update
  opkg install block-mount kmod-fs-ext4 e2fsprogs fdisk

  # Configure rootfs_data partition

  DEVICE="$(sed -n -e "/\s\/overlay\s.*$/s///p" /etc/mtab)"
  uci -q delete fstab.rwm
  uci set fstab.rwm="mount"
  uci set fstab.rwm.device="${DEVICE}"
  uci set fstab.rwm.target="/rwm"
  uci commit fstab

  # Format SD card
  DEVICE="/dev/sda1"
  mkfs.ext4 ${DEVICE}

  # Configure extroot
  BLOCK_INFO=$(block info | grep sda1)

  if echo "$BLOCK_INFO" | grep -q  TYPE=\"ext4\"; then
          echo $'\nSDA partition formatted correctly'
  else
          echo $'\nError formatting SDA partition'; exit 1
  fi

  eval $(block info ${DEVICE} | grep -o -e "UUID=\S*")
  uci -q delete fstab.overlay
  uci set fstab.overlay="mount"
  uci set fstab.overlay.uuid="${UUID}"
  uci set fstab.overlay.target="/overlay"
  uci commit fstab

  # Transfer content to external drive and reboot

  mkdir -p /tmp/cproot
  mount --bind /overlay /tmp/cproot
  mount ${DEVICE} /mnt
  tar -C /tmp/cproot -cvf - . | tar -C /mnt -xf -
  umount /tmp/cproot /mnt

  /etc/init.d/cron start

  reboot
}


main()
{
  # First steps with x750
  echo -e "First steps x750"
  custom_banner
  extroot_config
}

main "$@"
exit $?

