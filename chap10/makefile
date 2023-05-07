BUILD_DIR = ./build
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I kernel/ -I device/ -I thread/
ASFLAGS = -f elf
ASBINLIB = -I boot/include/
CFLAGS = -Wall -m32 -fno-stack-protector $(LIB) -c -fno-builtin -W -Wstrict-prototypes -Wmissing-prototypes
LDFLAGS = -m elf_i386 -Ttext $(ENTRY_POINT) -e main -Map $(BUILD_DIR)/kernel.map
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o \
       $(BUILD_DIR)/timer.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o \
       $(BUILD_DIR)/debug.o $(BUILD_DIR)/string.o $(BUILD_DIR)/bitmap.o\
       $(BUILD_DIR)/memory.o $(BUILD_DIR)/thread.o $(BUILD_DIR)/switch.o \
       $(BUILD_DIR)/list.o $(BUILD_DIR)/sync.o $ $(BUILD_DIR)/ioqueue.o \
       $(BUILD_DIR)/keyboard.o $(BUILD_DIR)/console.o


##############     MBR代码编译     ############### 
$(BUILD_DIR)/mbr.bin: boot/mbr.asm
	$(AS) $(ASBINLIB) $< -o $@

##############     bootloader代码编译     ###############
$(BUILD_DIR)/loader.bin: boot/loader.asm
	$(AS) $(ASBINLIB) $< -o $@

############ C 代码编译 ##############

$(BUILD_DIR)/ioqueue.o: device/ioqueue.c device/ioqueue.h kernel/interrupt.h \
					kernel/global.h kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/keyboard.o: device/keyboard.c device/keyboard.h lib/kernel/print.h \
					kernel/interrupt.h lib/kernel/io.h kernel/global.h \
					device/ioqueue.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD_DIR)/console.o: device/console.c device/console.h lib/kernel/print.h \
					lib/stdint.h thread/sync.h thread/thread.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD_DIR)/sync.o: thread/sync.c thread/sync.h kernel/list.h kernel/global.h \
					kernel/debug.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@	
$(BUILD_DIR)/thread.o: thread/thread.c thread/thread.h lib/stdint.h \
        				kernel/global.h kernel/bitmap.h kernel/memory.h lib/string.h \
        				lib/stdint.h lib/kernel/print.h kernel/interrupt.h kernel/debug.h \
					kernel/list.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/print.h	\
					 lib/stdint.h kernel/init.h lib/string.h device/console.h \
					 
					
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/bitmap.o: kernel/bitmap.c kernel/bitmap.h \
					lib/stdint.h lib/string.h lib/kernel/print.h \
					kernel/interrupt.h kernel/debug.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/memory.o: kernel/memory.c kernel/memory.h \
					lib/stdint.h lib/kernel/print.h kernel/bitmap.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/string.o: lib/string.c lib/string.h   \
					 kernel/debug.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@


$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h \
        			 	lib/stdint.h kernel/interrupt.h device/timer.h \
        			 	thread/thread.h device/keyboard.h device/console.h 
	$(CC) $(CFLAGS) $< -o $@


$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h \
        				  lib/stdint.h kernel/global.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@


$(BUILD_DIR)/timer.o: device/timer.c device/timer.h lib/stdint.h \
        			  lib/kernel/io.h lib/kernel/print.h kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@


$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h \
        			  lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/list.o: kernel/list.c kernel/list.h kernel/global.h lib/stdint.h \
	        			kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@




##############    汇编代码编译    ###############
$(BUILD_DIR)/kernel.o: kernel/kernel.asm
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/print.o: lib/kernel/print.asm
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/switch.o: thread/switch.asm
	$(AS) $(ASFLAGS) $< -o $@

##############    链接所有目标文件    #############
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@


.PHONY: mk_dir hd clean all

mk_dir:
	if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR); fi

hd:
	sudo dd if=$(BUILD_DIR)/kernel.bin of=../bochs/bin/hd60M.img bs=512 count=200 seek=9 conv=notrunc

clean:
	cd $(BUILD_DIR) && rm -f ./*

build: $(BUILD_DIR)/kernel.bin

all: mk_dir build hd

