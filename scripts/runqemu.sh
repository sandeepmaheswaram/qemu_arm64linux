#qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel linux-5.15.141/arch/arm64/boot/Image.gz -serial stdio -append "serial=ttyAMA0"

qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel linux-5.15.141/arch/arm64/boot/Image.gz  -initrd rootfs.cpio.gz -serial stdio -append "root=/dev/mem serial=ttyAMA0"
