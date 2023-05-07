#include "print.h"
#include "debug.h"
#include "init.h"
#include "../thread/thread.h"

void k_thread_a(void*);
void k_thread_b(void*);
int main(){
        put_str("I am kernel\n");
        init_all();
        asm volatile("sti");    //开启中断
        //ASSERT(strcmp("test", "test"));
        thread_start("k_thread_a", 31, k_thread_a, "argA");
        thread_start("k_thread_b", 8, k_thread_a, "argB");
        while(1) {
         put_str("Main");
        }
        return 0;
}

/* 在线程中运行的函数 */
void k_thread_a(void* arg) {     
   char* para = arg;
   while(1) {
      put_str(para);
   }
}

void k_thread_b(void* arg) {     
   char* para = arg;
   while(1) {
      put_str(para);
   }
}
