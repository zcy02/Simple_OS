#include "init.h"


/* 负责初始化所有模块 */
void init_all(){
        put_str("init_all\n");
        idt_init();             // 初始化 中断
        timer_init();           // 初始化 PIT
        console_init(); //提前了console init 便于打印调试信息
	mem_init();		// 初始化内存池
        thread_init();
        keyboard_init();
        tss_init();
        syscall_init();   // 初始化系统调用
}
