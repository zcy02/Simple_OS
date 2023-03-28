%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

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

total_memory dd 0

; GDT 指针
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE

ards_buf times 244 db 0
ards_cnt dw 0

loader_start:
    xor ebx, ebx
    mov edx, 0x534d4150
    mov di, ards_buf
    .memory_probe_0xe820:
        mov ax, 0xe820
        mov ecx, 20
        int 0x15
        jc .memory_probe_0xe801
        add di, cx
        inc word [ards_cnt]
        cmp ebx, 0
        jnz .memory_probe_0xe820
    mov cx,  [ards_cnt]
    mov ebx, ards_buf
    xor edx, edx
    .find_max_memory:
        mov eax, [ebx]
        add eax, [ebx+8]
        add ebx, 20
        cmp edx, eax
        jge .next_ards
        mov edx, eax    ; edx 若小于 eax，用 eax 赋值
    .next_ards:
        loop .find_max_memory   ; 循环 ecx 即 ards_cnt 次 
        jmp .memory_probe_finish

    .memory_probe_0xe801:
        mov ax, 0xe801
        int 0x15
        jc .memory_probe_0x88

        mov cx, 0x400
        mul cx  ; 高 16 位 dx，低 16 位 ax 
        shl edx, 16
        and eax, 0x0000FFFF
        or eax, edx
        add eax, 0x100000
        mov esi, eax

        xor eax, eax
        mov ax, bx
        mov ecx, 0x10000
        mul ecx ; 高 32 位 edx，低 32 位 eax
        add esi, eax

        mov edx, esi
        jmp .memory_probe_finish

    .memory_probe_0x88:
        mov ah, 0x88
        int 0x15
        jc .memory_probe_error
        and eax, 0x0000FFFF
        mov cx, 0x400
        mul cx
        shl edx, 16
        or edx, eax
        add edx, 0x100000

    .memory_probe_error:
        jmp $
    
    .memory_probe_finish:
        mov [total_memory], edx

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

