#include "init.h"

/* 负责初始化所有模块 */
void init_all() {
    put_str("init_all\n");
    idt_init();    // 初始化 中断
    timer_init();  // 初始化 PIT
    mem_init();    // 初始化内存池
    thread_init();
    console_init();
    keyboard_init();
    tss_init();
    syscall_init();  // 初始化系统调用
    intr_enable();   // 后面的ide_init需要打开中断
    ide_init();      // 初始化硬盘
    filesys_init();   // 初始化文件系统
}
