#include "print.h"
#include "debug.h"
#include "init.h"
int main(){
        put_str("I am kernel\n");
        init_all();
        //asm volatile("sti");    //开启中断
        ASSERT(strcmp("test", "test"));
        while(1);
        return 0;
}
