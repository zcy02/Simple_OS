%include "boot.inc"
SECTION MBR vstart=0x7c00 ;起始地址编译在0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800 ;文本模式显示适配器内存地址起始0xb8000
    mov gs, ax ; 存入GS作为段基址

    ;BIOS通过jmp0:0x07c00跳转，cs为0，利用ax间接赋值ds = es = ss = 0 
    ;栈指针指向MBR开始位置

    ;ah = 0x06 al = 0x00 调用int 0x06的BIOS提供的中断对应的函数完成清屏功能
    ;cx dx 分别存储左上角与右下角的左边
    mov ax,0x600 ;子功能号
    mov bx,0x700
    mov cx,0
    mov dx,0x184f ;窗口位置
    int 0x10 ;调用BIOS中断，清屏

    mov byte [gs:0x00], 'H'
    mov byte [gs:0x01], 0xf4
    mov byte [gs:0x02], 'e'
    mov byte [gs:0x03], 0xf4
    mov byte [gs:0x04], 'l'
    mov byte [gs:0x05], 0xf4
    mov byte [gs:0x06], 'l'
    mov byte [gs:0x07], 0xf4
    mov byte [gs:0x08], 'o'
    mov byte [gs:0x09], 0xf4
    mov byte [gs:0x0a], ' '
    mov byte [gs:0x0b], 0xf4
    mov byte [gs:0x0c], 'M'
    mov byte [gs:0x0d], 0xf4
    mov byte [gs:0x0e], 'B'
    mov byte [gs:0x0f], 0xf4
    mov byte [gs:0x10], 'R'
    mov byte [gs:0x11], 0xf4
    		
    mov eax, LOADER_START_SECTOR    ; 起始扇区LBA地址
    mov bx, LOADER_BASE_ADDR
    mov cx, 4
    call read_disk_m_16
    jmp LOADER_BASE_ADDR + 0x300
    

read_disk_m_16:
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
        mov [bx], ax    ; 向内存 0x900 传送数据
        add bx, 2   ; 每次两字节
        loop .read  ; cx 作为计数器
        ret
    ;预留两个字节 其余空余的全部用0填满 为使检测当前扇区最后两字节为0x55 0xaa 检测是否为有效扇区
    ;510 = 512字节-2预留字节  再减去（当前位置偏移量-段开始位置偏移量）求出来的是剩余空间
    times 510 - ($ - $$) db 0 
    db 0x55,0xaa
