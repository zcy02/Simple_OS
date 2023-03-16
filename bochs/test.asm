SECTION MBR vstart=0x7c00 ;起始地址编译在0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    ;BIOS通过jmp0:0x07c00跳转，cs为0，利用ax间接赋值ds = es = ss = 0 
    ;栈指针指向MBR开始位置

    ;ah = 0x06 al = 0x00 调用int 0x06的BIOS提供的中断对应的函数完成清屏功能
    ;cx dx 分别存储左上角与右下角的左边 详情看int 0x06函数调用
    mov ax,0x600 ;子功能号
    mov bx,0x700
    mov cx,0
    mov dx,0x184f ;窗口位置
    int 0x10 ;调用BIOS中断，清屏

    mov ah,3 ;3号子功能获取光标位置
    mov bh,0 ;在第0页
    int 0x10 ;调用BIOS中断，获取光标位置
    
    mov ax,message
    mov bp,ax
    
    mov cx,10 ;串长度
    mov ax,0x1301 ;ah为子功能13，al设置写字符方式01
    mov bx,0xF4 ;bh为页号，bl为属性
    int 0x10 ;写字符串
    		
    jmp $ ;无限循环 悬停
    
    ;字符串声明 db == define byte dw == define word ascii一个字符占一个字节
    message db "HELLO MBR!" 
    
    ;预留两个字节 其余空余的全部用0填满 为使检测当前扇区最后两字节为0x55 0xaa 检测是否为有效扇区
    ;510 = 512字节-2预留字节  再减去（当前位置偏移量-段开始位置偏移量）求出来的是剩余空间
    times 510 - ($ - $$) db 0 
    db 0x55,0xaa
