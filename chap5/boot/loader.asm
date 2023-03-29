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
        add eax, [ebx + 8]
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

    call setup_page
    sgdt [gdt_ptr]
    mov ebx, [gdt_ptr + 2]  ; 获得 gdt_base
    or dword [ebx + 0x18 + 4], 0xc0000000
    ; gdt 第三个描述符 video，每个 8B，取高 4B，段基址加上 3GB
    add dword [gdt_ptr + 2], 0xc0000000
    add esp, 0xc0000000

    mov eax, PAGE_DIR_TABLE_ADDR
    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    lgdt [gdt_ptr]
    mov byte [gs:160], 'V'
    mov byte [gs:162], 'i'
    mov byte [gs:164], 'r'
    mov byte [gs:166], 't'
    mov byte [gs:168], 'u'
    mov byte [gs:170], 'a'
    mov byte [gs:172], 'l'
    jmp $

setup_page:
    xor eax, eax
    mov ecx, 4096
    mov edi, 0x100000
    rep stosb   ; 将页目录表内存清零

.create_pde:
    mov eax, PAGE_DIR_TABLE_ADDR
    add eax, 0x1000 ; 第一页的物理地址
    mov ebx, eax
    or eax, PAGE_P | PAGE_RW_W | PAGE_US_U
    mov [PAGE_DIR_TABLE_ADDR], eax  ; 首个 PDE
    mov [PAGE_DIR_TABLE_ADDR + 0xc00], eax  
    ; 高 10 位为 0x300，第 768 个 PDE 的物理地址，高 3GB 以上对应低端 4MB 以内
    ; 0x300 = 768 以上的目录项用于内核空间
    sub eax, 0x1000
    mov [PAGE_DIR_TABLE_ADDR + 4092], eax
    ; 最后一个 1023 目录项指向页目录表物理地址，将页目录表作为页表看待

    mov ecx, 256    ; 1MB 低端内存占 256 页
    mov eax, PAGE_P | PAGE_RW_W | PAGE_US_U
    mov esi, 0
.create_kernel_pte:
    mov [ebx + esi*4], eax
    add eax, 0x1000   ; 下一页的物理地址
    inc esi
    loop .create_kernel_pte
 
    mov eax, PAGE_DIR_TABLE_ADDR
    add eax, 0x2000
    or eax, PAGE_P | PAGE_RW_W | PAGE_US_U
    mov ebx, PAGE_DIR_TABLE_ADDR
    mov ecx, 254    ; 769-1022 的页目录项
    mov esi, 769
    ; 769 号 PDE 指向页目录表
.create_kernel_pde:
    mov [ebx + esi*4], eax
    inc esi
    add eax, 0x1000
    loop .create_kernel_pde
    ret






