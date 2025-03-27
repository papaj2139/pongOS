ASM=nasm
CC=gcc
LD=ld

ASMFLAGS=-f bin
CFLAGS=-m16 -march=i386 -nostdlib -nostdinc -fno-builtin -ffreestanding
LDFLAGS=-T kernel.ld --oformat binary

BOOT_DIR=boot
KERNEL_DIR=kernel
BUILD_DIR=build

BOOT_SRC=$(BOOT_DIR)/boot.asm
KERNEL_SRC=$(KERNEL_DIR)/kernel_entry.asm

BOOT_BIN=$(BUILD_DIR)/boot.bin
KERNEL_BIN=$(BUILD_DIR)/kernel.bin
OS_IMAGE=$(BUILD_DIR)/pongos.bin
OS_IMG=$(BUILD_DIR)/pongos.img

all: $(BUILD_DIR) $(OS_IMAGE)

img: $(OS_IMG)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BOOT_BIN): $(BOOT_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(KERNEL_BIN): $(KERNEL_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	#pad the image
	dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=2880
	dd if=$(BOOT_BIN) of=$(OS_IMAGE) conv=notrunc
	dd if=$(KERNEL_BIN) of=$(OS_IMAGE) seek=1 conv=notrunc,sync

$(OS_IMG): $(OS_IMAGE)
	cp $(OS_IMAGE) $(OS_IMG)

clean:
	rm -rf $(BUILD_DIR)

run: $(OS_IMAGE)
	qemu-system-i386 \
		-display sdl \
		-drive format=raw,file=$(OS_IMAGE),if=floppy,index=0,media=disk,cache=none \
		-audiodev alsa,id=snd0,out.mixing-engine=on \
		-machine pcspk-audiodev=snd0
#if you dont have alsa this shit for pulseaudio
run-pa: $(OS_IMAGE)
	XDG_RUNTIME_DIR=/run/user/$(shell id -u) \
	qemu-system-i386 \
		-display sdl \
		-drive format=raw,file=$(OS_IMAGE),if=floppy,index=0,media=disk \
		-audiodev pa,id=snd0 \
		-machine pcspk-audiodev=snd0

run-img: $(OS_IMG)
	qemu-system-i386 \
		-display sdl \
		-drive format=raw,file=$(OS_IMG),if=floppy,index=0,media=disk,cache=none \
		-audiodev alsa,id=snd0,out.mixing-engine=on \
		-machine pcspk-audiodev=snd0
