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
    		
    jmp $ ;无限循环 悬停
    
    ;预留两个字节 其余空余的全部用0填满 为使检测当前扇区最后两字节为0x55 0xaa 检测是否为有效扇区
    ;510 = 512字节-2预留字节  再减去（当前位置偏移量-段开始位置偏移量）求出来的是剩余空间
    times 510 - ($ - $$) db 0 
    db 0x55,0xaa
