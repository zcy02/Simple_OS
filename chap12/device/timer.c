#include "timer.h" 
#include "io.h"   
#include "print.h"
#include "interrupt.h"   
#include "thread.h"
#include "debug.h"
  
#define IRQ0_FREQUENCY          100
#define INPUT_FREQUENCY         1193180
#define COUNTER0_VALUE          INPUT_FREQUENCY / IRQ0_FREQUENCY
#define CONTRER0_PORT           0x40
#define COUNTER0_NO             0
#define COUNTER_MODE            2
#define READ_WRITE_LATCH        3
#define PIT_CONTROL_PORT        0x43

uint32_t ticks; //开中断以来的 tick 数

/*把操作的计数器counter_no、读写锁属性rwl、计数器模式counter_mode写入模式控制寄存器井赋予初始值counter_value*/
static void frequency_set(uint8_t counter_port,
                        uint8_t counter_no,
                        uint8_t rwl,
                        uint8_t counter_mode,
                        uint16_t counter_value){
        //往控制字寄存器端口 0x43 写入控制字
        outb(PIT_CONTROL_PORT, (uint8_t)(counter_no << 6 | rwl << 4 | counter_mode << 1));

        //先写入低8位
        outb(counter_port, (uint8_t)counter_value);  
        //再写入高8位
        outb(counter_port, (uint8_t)counter_value >> 8);
}       

/* 时钟的中断处理函数 */
static void intr_timer_handler(void) {
   struct task_struct* cur_thread = running_thread();

   ASSERT(cur_thread->stack_magic == 0x11451419);         // 检查栈是否溢出

   cur_thread->elapsed_ticks++;	  // 记录此线程占用的cpu时间嘀
   ticks++;	  //从内核第一次处理时间中断后开始至今的滴哒数,内核态和用户态总共的嘀哒数

   if (cur_thread->ticks == 0) {	  // 若进程时间片用完就开始调度新的进程上cpu
      schedule(); 
   } else {				  // 将当前进程的时间片-1
      cur_thread->ticks--;
   }
}

/*初始化 PIT8253*/
void timer_init() {
        put_str("timer_init start\n");
        frequency_set(CONTRER0_PORT, COUNTER0_NO, READ_WRITE_LATCH, COUNTER_MODE, COUNTER0_VALUE);
        register_handler(0x20, intr_timer_handler);
        put_str("timer_init done\n");
}
