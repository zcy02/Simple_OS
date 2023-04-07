[bits 32]
%define ERROR_CODE nop  ;为了栈中格式统一，如果 CPU 在异常中已经自动压入错误码，这里不做操作
%define ZERO push 0     ;为了栈中格式统一，如果 CPU 在异常中没有自动压入错误码，这里填充 0

extern put_str          ;声明外部函数，告诉编译器在链接的时候可以找到
extern intr_handler_table        ;声明 c 注册的中断处理函数数组

section .data
intr_str db "interrupt occur!", 0xa, 0

global intr_entry_table
intr_entry_table:

%macro VECTOR 2
section .text
intr%1entry:            ;每个中断处理程序都要压入中断向量号，所以1个中断类型1个处理程序，自己知道自己的中断号是多少
        ;无错误时，压入0占位
        %2

        ;保存上下文环境
        push ds
        push es
        push fs
        push gs
        pushad

        ;如果从片上进入中断，除了往片上发送 EOI 外，还要往主片上发送 EOI，因为后面要在 8259A 芯片上设置手动结束中断，所以这里手动发送 EOI
        mov al, 0x20    ;中断结束命令 EOI
        out 0xa0, al    ;往从片发送
        out 0x20, al    ;往主片发送

        push %1         ;不管中断处理程序是否需要，一律压入中断向量号   
        call [intr_handler_table + %1*4]

        jmp  intr_exit

section .data           ;这个 section .data 的作用就是让数组里全都是地址，编译器会将属性相同的 Section 合成一个大的 Segmengt，所以这里就是紧凑排列的数组了
        dd intr%1entry  ;存储各个中断入口程序的地址，形成 intr_entry_table 数组

%endmacro

section .text
global intr_exit
intr_exit:
        ;恢复上下文环境
        add esp, 4      ;跳过参数中断号
        popad
        pop gs
        pop fs
        pop es
        pop ds
        add esp, 4      ;手动跳过错误码
        iretd

VECTOR 0x00, ZERO
VECTOR 0x01, ZERO
VECTOR 0x02, ZERO
VECTOR 0x03, ZERO
VECTOR 0x04, ZERO

VECTOR 0x05, ZERO
VECTOR 0x06, ZERO
VECTOR 0x07, ZERO
VECTOR 0x08, ZERO
VECTOR 0x09, ZERO

VECTOR 0x0a, ZERO
VECTOR 0x0b, ZERO
VECTOR 0x0c, ZERO
VECTOR 0x0d, ZERO
VECTOR 0x0e, ZERO

VECTOR 0x0f, ZERO
VECTOR 0x10, ZERO
VECTOR 0x11, ZERO
VECTOR 0x12, ZERO
VECTOR 0x13, ZERO

VECTOR 0x14, ZERO
VECTOR 0x15, ZERO
VECTOR 0x16, ZERO
VECTOR 0x17, ZERO
VECTOR 0x18, ZERO

VECTOR 0x19, ZERO
VECTOR 0x1a, ZERO
VECTOR 0x1b, ZERO
VECTOR 0x1c, ZERO
VECTOR 0x1d, ERROR_CODE

VECTOR 0x1f, ZERO
VECTOR 0x20, ZERO
VECTOR 0x21, ZERO
VECTOR 0x22, ZERO
VECTOR 0x23, ZERO
VECTOR 0x24, ZERO
VECTOR 0x25, ZERO
VECTOR 0x26, ZERO
VECTOR 0x27, ZERO
VECTOR 0x28, ZERO
VECTOR 0x29, ZERO
VECTOR 0x2a, ZERO
VECTOR 0x2b, ZERO
VECTOR 0x2c, ZERO
VECTOR 0x2d, ZERO
VECTOR 0x2e, ZERO
VECTOR 0x2f, ZERO