#!/bin/sh

cd
BASE_DIR="/srv/smartbox/firmware"

preserve_opkg_list()
{
  # Save opkg lists on extroot
  echo $'#\n#\n#\nTransfering files to external memory'
  sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" /etc/opkg.conf
  opkg update
}

create_swap()
{
  #if ! free | grep Swap ; then
    # Enable SWAP Memory
    echo $'#\n#\n#\nCreating SWAP Memory'
    # Create swap file
    dd if=/dev/zero of=/overlay/swap bs=1M count=256
    mkswap /overlay/swap

    # Enable swap file
    uci -q delete fstab.swap
    uci set fstab.swap="swap"
    uci set fstab.swap.device="/overlay/swap"
    uci commit fstab
    /etc/init.d/fstab boot
  #else
    echo $'#\n#\n#\nSWAP Memory Exists'
  #fi

}

enable_ifaces(){
  if ! ifconfig | grep wwan0 ; then
    # Enable and connect WWAN
    echo $'#\n#\n#\nEnabling WWAN module'
    cp /srv/network /etc/config/network
    cp /srv/wireless /etc/config/wireless
    /etc/init.d/network restart
    uqmi -d /dev/cdc-wdm0 --start-network internet --autoconnect
    opkg install socat
  else
    echo $'#\n#\n#\nWWAN enabled'
  fi
}


install_packages()
{
  #opkg update
  # TBD
}

main()
{
  # Setup Huey Huitzil
  echo -e "Setting up Huey Huitzil"

  preserve_opkg_list
  create_swap
  enable_ifaces
  install_packages
  # Save setup log for debug
  logread >> /srv/setup-debug.log
}

main "$@"
exit $?

