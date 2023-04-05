#include "print.h"
#include "init.h"
int main(){
        put_str("I am kernel\n");
        init_all();
        asm volatile("sti");    //开启中断
        while(1);
        return 0;
}