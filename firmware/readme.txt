固件版本 NodeMCU 2.2.1
包含模块：
    crypto, file, gpio, net, node, sjson, tmr, uart, wifi
烧录命令：
python esptool.py -p /dev/ttyUSB0 write_flash -fm dio 0x00000 xxx.bin
清除命令：
python esptool.py -p /dev/ttyUSB0 erase_flash
重置LFS：
node.flashreload("lfs.img")