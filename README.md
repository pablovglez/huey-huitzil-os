# huey-huitzil-os
### An Huey Huitzil OpenWRT Imagebuilder.


Before continuing, make sure you are connected to Internet.

You'll select a stable OpenWRT version and provide the paths of Extra packages list and Extra Files folder path.

### Usage
```bash
chmod +x run_imagebuilder.sh
./run_imagebuilder.sh
```
The output will be in the `output` folder.

### Example of Extra packages list
```text
qmi-utils mwan3 kmod-usb-net
```

### Example of Extra Files folder structure
```lua
├── etc/
│   ├── config/
│   │   ├── network
│   │   ├── wireless
│   │   ├── dhcp
│   │   ├── firewall
└── banner
```

### More Information
It is strongly recommended to read the OpenWRT documentation for more information on how to use the image builder and customize your images.

https://openwrt.org/docs/guide-user/additional-software/imagebuilder

### Limitations
- The script is designed to work with Raspberry Pi 3+

### Modify filesystem to use all the available storage on the SD card

1. find your device address usin _lsblk_ and unmount it

```bash
lsblk

...

sdc      8:32   1  14.8G  0 disk 
├─sdc1   8:33   1    64M  0 part /media/efisio/boot
└─sdc2   8:34   1   104M  0 part /media/efisio/rootfs

sudo fdisk /dev/sdc
```

2. Update the second partition, by using the following commands.
Inside fdisk make sure you list the existing partitions to find the starting points of existing partitions

```bash
sudo fdisk /dev/sdc

# Show existing partitions
Command (m for help): p
Disk /dev/sdc: 14.77 GiB, 15854469120 bytes, 30965760 sectors
Disk model: Storage Device  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xaa121fe4

Device     Boot Start    End Sectors Size Id Type
/dev/sdc1  *     8192 139263  131072  64M  c W95 FAT32 (LBA)
/dev/sdc2      147456 360447  211992 104M 83 W95 Linux

# Delete partition 2
Command (m for help): d
Partition number (1,2, default 2): 2

Partition 2 has been deleted.

# Create a new partition
Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (2-4, default 2): 2
First sector (2048-30965759, default 2048): 147456
Last sector, +/-sectors or +/-size{K,M,G,T,P} (147456-30965759, default 30965759): 

# When asked, type n to avoid removing the signature
Do you want to remove the signature? [Y]es/[N]o: n

# Write the changes to the disk
Command (m for help): w

The partition table has been altered.
Syncing disks.
```
