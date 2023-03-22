%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

; 构建 GDT 和内部描述符
GDT_BASE:   dd 0x00000000   ; 第 0 个为空
            dd 0x00000000
CODE_DESC:  dd 0x0000FFFF   ; 基址 0，limit 全 1
            dd DESC_CODE_HIGH4B ; 定义的代码段高 4B 
DATA_STACK_DESC:    dd 0x0000FFFF
                    dd DESC_DATA_HIGH4B ; 数据段高 4B
VIDEO_DESC: dd 0x80000007
            dd DESC_VIDEO_HIGH4B
; 和高四位拼出段基址 0xb8000，limit = (0xBFFFF - 0xB8000) / 4K = 0x7
GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1
times 60 dq 0
SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

gdt_ptr dw GDT_LIMIT
        dd GDT_BASE

msg db 'loader in real mode'

loader_start:
    mov sp, LOADER_BASE_ADDR
    mov bp, msg
    mov cx, 19 ; 串长度
    mov ax,0x1301 ;a h为子功能13，al设置写字符方式01
    mov bx,0x00F4 ; bh为页号，bl为属性
    mov dx, 0x1800  ; 位置左下角
    int 0x10 ; 写字符串

    ; 进入保护模式
    in al, 0x92
    or al, 0x02
    out 0x92, al

    lgdt [gdt_ptr]

    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start    ; 刷新流水线



[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    mov byte [gs:160], 'H'
    mov byte [gs:162], 'E'
    mov byte [gs:164], 'L'
    mov byte [gs:166], 'L'
    mov byte [gs:168], 'O'
    
    jmp $

