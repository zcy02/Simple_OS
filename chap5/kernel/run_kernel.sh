gcc -m32 -c -o kernel.o kernel.c && ld -m elf_i386 kernel.o -Ttext 0xc0001500 -e main -o kernel.bin && dd if=kernel.bin of=../../bochs/bin/hd60M.img bs=512 count=200 seek=9 conv=notrunc