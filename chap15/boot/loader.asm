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

    ; 加载内核
    mov eax, KERNEL_SECTOR
    mov ebx, KERNEL_BIN_BASE_ADDR
    mov ecx, 200
    ; 扇区号、加载到的内存地址、扇区数
    call read_disk_m_32

    ; 分页启动
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

    lgdt [gdt_ptr]  ; 重新加载 GDT
    mov byte [gs:160], 'V'
    mov byte [gs:162], 'i'
    mov byte [gs:164], 'r'
    mov byte [gs:166], 't'
    mov byte [gs:168], 'u'
    mov byte [gs:170], 'a'
    mov byte [gs:172], 'l'
    
    jmp SELECTOR_CODE:enter_kernel

enter_kernel:
    call kernel_init
    mov esp, 0xc009f000 ; 选择保守的栈底，增加栈空间
    jmp KERNEL_ENTER_ADDR   ; 0c001500 -> 0x1500

setup_page:
    xor eax, eax
    mov ecx, 4096
    mov edi, 0x100000
    cld
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

kernel_init:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov dx, [KERNEL_BIN_BASE_ADDR + 42] ; 每个 entry 大小，e_phentsize
    mov ebx, [KERNEL_BIN_BASE_ADDR + 28]    ; pht 在文件中的偏移量，e_phoff
    add ebx, KERNEL_BIN_BASE_ADDR   ; 加上基址得到第一个 program header
    mov cx, [KERNEL_BIN_BASE_ADDR + 44] ; program header 数量
.traverse_segment:
    cmp byte [ebx + 0], PT_NULL ; 若为空类型
    je .pt_is_null

    push dword [ebx + 16]   ; 为 mem_cpy 压参数 1 p_filesz 大小
    mov eax, [ebx + 4]  ; p_offset
    add eax, KERNEL_BIN_BASE_ADDR   ; 算出该段物理地址
    push eax    ; 2 压入该段物理地址
    push dword [ebx + 8]    ; 3 p_vaddr 目标虚拟地址

    call mem_cpy
    add esp, 12 ; 恢复栈指针

.pt_is_null:
    add ebx, edx    ; 下一个 entry
    loop .traverse_segment
    ret

mem_cpy:
    cld ; clean direction，DF = 0， esi edi 自动增加
    push ebp    ; 先备份 ebp
    mov ebp, esp    ; 栈顶
    push ecx    ; 备份 ecx 后面 rep 要借助 ecx 完成计数复制内存

    mov edi, [ebp + 8]  ; 取得目的地址
    mov esi, [ebp + 12] ; 取得源地址
    mov ecx, [ebp + 16] ; 取得段尺寸
    rep movsb   ; 拷贝

    pop ecx ; 恢复 ecx
    pop ebp ; 最后恢复 ebp
    ret

read_disk_m_32:
    mov esi, eax    ;out要用到al，备份到esi
    mov di, cx  ;读取数据用到cx，备份
    ; 设置Sector count
    mov dx, 0x1f2
    mov al, cl
    out dx, al
    mov eax, esi
    ; 设置LBA地址
    mov dx, 0x1f3
    out dx, al  ; 0-7位 对应 al

    mov cl, 8
    shr eax, cl ; 右移8位，al 此时对应 8-15位
    mov dx, 0x1f4
    out dx, al

    shr eax, cl ; 再右移8位， al 此时对应 16-23位
    mov dx, 0x1f5
    out dx, al

    shr eax, cl ; 右移8位
    and al, 0x0f    ; mask 取al低四位，即对应 24-27位
    or al, 0xe0    ; 高四位设置 1110，LBA模式、主盘
    mov dx, 0x1f6
    out dx, al

    ; 读硬盘命令
    mov dx, 0x1f7   ; command reg
    mov al, 0x20    ; 0x20 read sector
    out dx, al

    .not_ready:
        nop
        in al, dx   ; 读 0x1f7 时为 status reg
        and al, 0x88    ; mask 取7、3位（BYS 和 DRQ）
        cmp al, 0x08    ; 第3位为1表示硬盘控制器已准备好数据传输
        jnz .not_ready

        ; 从Data reg读数据
        
        mov ax, di  ; 扇区数
        mov dx, 256 ; 每个扇区 512B，每次读 2B，每个扇区 256 次
        mul dx  ; dx 乘以 ax，结果低16位放入 ax，高16位在 dx
        mov cx, ax  ; 读盘次数存入 loop 计数器 cx 中
        mov dx, 0x1f0
    .read:
        in ax, dx   ; 读硬盘
        mov [ebx], ax    ; 32 位版本改用 ebx
        add ebx, 2   ; 每次两字节
        loop .read  ; cx 作为计数器
        ret



