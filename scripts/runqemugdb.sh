#This for launching gdb server from qemu -s -S are the options related to gdb 

qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel linux-5.15.141/arch/arm64/boot/Image.gz  -initrd rootfs.cpio.gz -serial stdio -append "root=/dev/mem serial=ttyAMA0" -s -S
