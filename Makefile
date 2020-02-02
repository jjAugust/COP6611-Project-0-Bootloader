all:
	gcc -MD -fno-builtin -nostdinc -fno-stack-protector -Os -g -m32 -I. -c -o ./boot/boot0/boot0.o ./boot/boot0/boot0.S
	ld -nostdlib -m elf_i386 -N -e start -Ttext 0x7c00 -o ./boot/boot0/boot0.elf ./boot/boot0/boot0.o
	objcopy -S -O binary ./boot/boot0/boot0.elf boot0
	gcc -MD -fno-builtin -nostdinc -fno-stack-protector -Os -g -m32 -I. -c -o ./boot/boot1/boot1.o ./boot/boot1/boot1.S
	gcc -MD -fno-builtin -nostdinc -fno-stack-protector -Os -g -m32 -I. -c -o ./boot/boot1/boot1lib.o ./boot/boot1/boot1lib.c
	gcc -MD -fno-builtin -nostdinc -fno-stack-protector -Os -g -m32 -I. -c -o ./boot/boot1/boot1main.o ./boot/boot1/boot1main.c
	gcc -MD -fno-builtin -nostdinc -fno-stack-protector -Os -g -m32 -I. -c -o ./boot/boot1/exec_kernel.o ./boot/boot1/exec_kernel.S
	ld -nostdlib -m elf_i386 -N -e start -Ttext 0x7e00 -o ./boot/boot1/boot1.elf ./boot/boot1/boot1.o ./boot/boot1/boot1main.o ./boot/boot1/boot1lib.o ./boot/boot1/exec_kernel.o
	objcopy -S -O binary ./boot/boot1/boot1.elf boot1
	gcc -MD -fno-builtin -nostdinc -fno-stack-protector -D_KERN_ -Ikern -Ikern/kern -I. -m32 -O0 -c -o ./kern/init/entry.o ./kern/init/entry.S
	ld -o kernel -nostdlib -e start -m elf_i386 -Ttext=0x00100000 ./kern/init/entry.o -b binary
	dd if=/dev/zero of=project0.img bs=512 count=256
	parted -s project0.img "mktable msdos mkpart primary 63s -1s set 1 boot on"
	dd if=boot/boot0/boot0 of=project0.img bs=446 count=1 conv=notrunc
	dd if=boot/boot1/boot1 of=project0.img bs=512 count=62 seek=1 conv=notrunc
	dd if=kern/init/kernel of=project0.img bs=512 seek=63 conv=notrunc

	
	