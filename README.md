# qemu_arm64linux
This is made with reference from below link
https://lukaszgemborowski.github.io/articles/minimalistic-linux-system-on-qemu-arm.html

This is done on ubuntu 20.4 virtual box running on Windows 10 x86_64 laptop.
Should work on any linux host.

# Install QEMU
  
  sudo apt install qemu-system

# Install the cross compiler for arm64

sudo apt install gcc-aarch64-linux-gnu

# Download linux kernel source

$ wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.141.tar.xz

# Download the busybox

$ wget http://busybox.net/downloads/busybox-1.36.0.tar.bz2

# Extract downloaded archives:

$ tar -xf linux-5.15.141.tar.xz

$ tar -xf busybox-1.36.0.tar.bz2

# Building ARM64 Linux kernel
To do this as quick as possible we will use default configuration for qemu. To cross-compile Linux you need to know two things:

$ cd linux-5.15.141

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig

.config file will be generated after this. We can further customize and disable unncessary configs by running below command

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig

Compile the kernel after completing configuration

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

# Launch the qemu with the below command

$ qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel linux-5.15.141/arch/arm64/boot/Image.gz -serial stdio -append "serial=ttyAMA0"


Let’s talk about the arguments passed to qemu:

-M – the board name, used for qemu  
-cpu cpuname is mandatory for arm64 (eg: cortex-a53,cortex-a72)  
-kernel – the kernel binary itself  
-dtb – device tree for the board. Not used here as qemu picks virt.dtb internally  
-serial – where the console should be printed, we want it on stdio.  
-append – append additional kernel command line arguments. We need to inform kernel where to print stuff by default. We want it to be ttyAMA0 device (first serial port)  


You should see the kernel booting and finally… kernel panic.

Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)  
CPU: 0 PID: 1 Comm: swapper/0 Not tainted 5.15.141 #1  
Hardware name: linux,dummy-virt (DT)  


Don’t worry, it’s expected. You do not have a device with a valid root file system. We will provide it in a while and this is the reason why we want to have BusyBox. It will provide basic functionality for our small system.

# Busybox
Go back one directory up to the place where you have extracted your BusyBox sources. Go into this directory and configure BusyBox, you will need almost the same command line arguments as for Linux kernel:

$ cd busybox-1.36.0

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig

Now we have default configuration file created. We need to tune it a little by making busybox executable statically linked as we don’t want to provide additional shared libraries. We can do this by invoking:

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig

Navigating to Busybox Settings -> Build Options and checking “Build BusyBox as a static binary (no shared libs)” option. Now we can proceed with compilation:

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

$ make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- install

This should be quite quick. Now we are ready to create our root filesystem image. We will put there init script, busybox and also provide proper directory layout.

# Root filesystem
So what this thing should contain? What do we want for our minimalistic Linux system? Only a few things:

init script – Kernel needs to run something as first process in the system.
Busybox – it will contain basic shell and utilities (like cd, cp, ls, echo etc)
Navigate back to our workspace and create directory named rootfs. In this directory create file named init, eg. vim rootfs/init

#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mknod -m 660 /dev/mem c 1 1

echo -e "\nHello!\n"

exec /bin/sh


Make it executable by:

$ chmod +x rootfs/init

Now copy busybox stuff there:

$ cp -av busybox-1.36.0/_install/* rootfs/

Now you should have almost everything, there is only one thing missing, ie. standard directory layout. Let’s create it:

$ mkdir -pv rootfs/{bin,sbin,etc,proc,sys,usr/{bin,sbin}}

That’s all. We will use contents of this directory as the init ram disk so we need to create cpio archive and compress it with gzip:

$ cd rootfs
$ find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../rootfs.cpio.gz

Note that we changed the current directory to rootfs first. This is because we don’t want “rootfs” to be prepended to file paths.

# Running
This part is pretty straight forward, we will run our kernel almost exactly as before:

$ qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel linux-5.15.141/arch/arm64/boot/Image.gz  -initrd rootfs.cpio.gz -serial stdio -append "root=/dev/mem serial=ttyAMA0"

There are two minor changes:

-initrd argument is added, it points to the initial ram disk
root=/dev/mem is added to -append string. It tells kernel from where we want to boot.
Now you should see shell prompt. You’re in your own Linux “distribution”. :-)

#Access the debugfs folders
$mount -t debugfs none /sys/kernel/debug -o mode=755
