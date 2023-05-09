[bits 32]
%define ERROR_CODE nop  ;为了栈中格式统一，如果 CPU 在异常中已经自动压入错误码，这里不做操作
%define ZERO push 0     ;为了栈中格式统一，如果 CPU 在异常中没有自动压入错误码，这里填充 0

extern put_str          ;声明外部函数，告诉编译器在链接的时候可以找到
extern idt_table        ;声明 c 注册的中断处理函数数组

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
        call [idt_table + %1*4]

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

VECTOR 0x00,ZERO
VECTOR 0x01,ZERO
VECTOR 0x02,ZERO
VECTOR 0x03,ZERO 
VECTOR 0x04,ZERO
VECTOR 0x05,ZERO
VECTOR 0x06,ZERO
VECTOR 0x07,ZERO 
VECTOR 0x08,ERROR_CODE
VECTOR 0x09,ZERO
VECTOR 0x0a,ERROR_CODE
VECTOR 0x0b,ERROR_CODE 
VECTOR 0x0c,ZERO
VECTOR 0x0d,ERROR_CODE
VECTOR 0x0e,ERROR_CODE
VECTOR 0x0f,ZERO 
VECTOR 0x10,ZERO
VECTOR 0x11,ERROR_CODE
VECTOR 0x12,ZERO
VECTOR 0x13,ZERO 
VECTOR 0x14,ZERO
VECTOR 0x15,ZERO
VECTOR 0x16,ZERO
VECTOR 0x17,ZERO 
VECTOR 0x18,ERROR_CODE
VECTOR 0x19,ZERO
VECTOR 0x1a,ERROR_CODE
VECTOR 0x1b,ERROR_CODE 
VECTOR 0x1c,ZERO
VECTOR 0x1d,ERROR_CODE
VECTOR 0x1e,ERROR_CODE
VECTOR 0x1f,ZERO 
VECTOR 0x20,ZERO	;时钟中断对应的入口
VECTOR 0x21,ZERO	;键盘中断对应的入口
VECTOR 0x22,ZERO	;级联用的
VECTOR 0x23,ZERO	;串口2对应的入口
VECTOR 0x24,ZERO	;串口1对应的入口
VECTOR 0x25,ZERO	;并口2对应的入口
VECTOR 0x26,ZERO	;软盘对应的入口
VECTOR 0x27,ZERO	;并口1对应的入口
VECTOR 0x28,ZERO	;实时时钟对应的入口
VECTOR 0x29,ZERO	;重定向
VECTOR 0x2a,ZERO	;保留
VECTOR 0x2b,ZERO	;保留
VECTOR 0x2c,ZERO	;ps/2鼠标
VECTOR 0x2d,ZERO	;fpu浮点单元异常
VECTOR 0x2e,ZERO	;硬盘
VECTOR 0x2f,ZERO	;保留

;;;;;;;;;;;;;;;;   0x80号中断   ;;;;;;;;;;;;;;;;
[bits 32]
extern syscall_table
section .text
global syscall_handler
syscall_handler:
;1 保存上下文环境
   push 0			    ; 压入0, 使栈中格式统一

   push ds
   push es
   push fs
   push gs
   pushad			    ; PUSHAD指令压入32位寄存器，其入栈顺序是:
				    ; EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI 
				 
   push 0x80			    ; 此位置压入0x80也是为了保持统一的栈格式

;2 为系统调用子功能传入参数
   push edx			    ; 系统调用中第3个参数
   push ecx			    ; 系统调用中第2个参数
   push ebx			    ; 系统调用中第1个参数

;3 调用子功能处理函数
   call [syscall_table + eax*4]	    ; 编译器会在栈中根据C函数声明匹配正确数量的参数
   add esp, 12			    ; 跨过上面的三个参数

;4 将call调用后的返回值存入待当前内核栈中eax的位置
   mov [esp + 8*4], eax	
   jmp intr_exit		    ; intr_exit返回,恢复上下文