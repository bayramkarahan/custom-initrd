#!/bin/bash
for directory in {crypto,fs,lib} \
    drivers/{block,ata,md,firewire} \
    drivers/{scsi,message,pcmcia,virtio} \
    drivers/usb/{host,storage}; 
    	do
    	#echo ${directory}
   find /lib/modules/$(uname -r)/kernel/${directory}/ -type f \
        -exec install {} initrd/lib/modules/$(uname -r)/moduller/ \;
	done
