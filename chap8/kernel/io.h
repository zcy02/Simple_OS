/****机器模式****
 *      b--输出寄存器最低8位：[a-d]l
 *      w--输出寄存器2个字节：[a-d]x
 * * * * * * ****/

#ifndef __LIB_IO_H
#define __LIB_IO_H
#include "stdint.h"

/* 向端口 port 写入一个字节 */
static inline void outb (uint16_t port, uint8_t data) {

        /*********************************************************
        对端口指定N表示0-255, d表示用dx存储端口号，
        %b0表示对应al，%w1表示对应dx */
        asm volatile ("outb %b0, %w1" : : "a" (data), "Nd" (port));
        /******************************************************/
        // 这里是 AT&T 语法的汇编语言，相当于： mov al. data
        //                                      mov dx, port
        //                                      out dx, al
}       

/* 将addr处起始的word_cnt个字写入端口port */
static inline void outsw(uint16_t port, const void* addr, uint32_t word_cnt) {  
        /*********************************************************
        + 表示此限制既做输入，又做输出,
        outsw 是把 ds:esi 处的 16 位的内容写入 port 端口,
        我们在设置段描述符时，已经将ds,es,ss段的选择子都设置为相同的值了， 此时不用担心数据错乱。 */
        asm volatile ("cld;rep outsw":"+S"(addr),"+c"(word_cnt):"d"(port));
        /*********************************************************/
        // 这里是 AT&T 语法的汇编语言，相当于： cld
        //                                      mov esi, addr
        //                                      mov ecx, word_cnt
        //                                      mov edx, port
        //                                      rep outsw
}  

/* 将从端口 port 读入一个字节返回 */
static inline uint8_t inb(uint16_t port){
        uint8_t data;
        asm volatile ("inb %w1,%b0": "=a"(data):"Nd"(port));
        // 这里是 AT&T 语法的汇编语言，相当于： mov dx, port
        //                                      in  al, dx
        //                                      mov [data], al

        return data;
}

/* 将从端口 port 读入的 word_cnt 个字写入 addr */
static inline void insw(uint16_t port, void* addr, uint32_t word_cnt){
        /*********************************************************
        insw 是将从端口 port 处读入的 16 位内容写入 es:edi 指向的内存，
        我们在设置段描述符时，已经将ds,es,ss段的选择子都设置为相同的值了，此时不用担心数据错乱． */
        asm volatile ("cld; rep insw" : "+D" (addr), "+c" (word_cnt): "d"(port): "memory" );
        /********************************************************/
        // 这里是 AT&T 语法的汇编语言，相当于： cld
        //                                      mov edi, addr
        //                                      mov ecx. word_cnt
        //                                      mov dx, port
        //                                      rep insw
}

#endif