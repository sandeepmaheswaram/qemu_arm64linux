#this doesnt have rootfs so it will panic
qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel linux-5.15.141/arch/arm64/boot/Image.gz -serial stdio -append "serial=ttyAMA0"
