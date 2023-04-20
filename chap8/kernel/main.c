#include "print.h"
#include "debug.h"
#include "init.h"
int main(){
        put_str("I am kernel\n");
        init_all();
        void* addr = kalloc(3);
        put_str("\n kalloc start vaddr: ");
        put_int((uint32_t)addr);
        put_str("\n");
        //asm volatile("sti");    //开启中断
        ASSERT(strcmp("test", "test"));
        while(1);
        return 0;
}
