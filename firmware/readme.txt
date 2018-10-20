固件版本 NodeMCU 2.2.1
包含模块：
    crypto, file, gpio, net, node, sjson, tmr, uart, wifi
烧录命令：
esptool.py --port COM5 write_flash -fm dio 0x00000 nodemcu_float_master_20181020.bin