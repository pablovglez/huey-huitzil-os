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