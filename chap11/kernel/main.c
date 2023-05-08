#include "print.h"
#include "init.h"
#include "thread.h"
#include "interrupt.h"
#include "console.h"
#include "process.h"

void k_thread_a(void*);
void k_thread_b(void*);
void k_thread_c(void*);
//void u_prog_a(void);
//void u_prog_b(void);
int test_var_a = 0, test_var_b = 0;

int main(void) {
   put_str("I am kernel\n");
   init_all();
   intr_enable();
   thread_start("k_thread_a", 31, k_thread_a, "argA ");
   thread_start("k_thread_b", 31, k_thread_b, "argB ");
   thread_start("k_thread_c", 31, k_thread_c, "argC ");
   //process_execute(u_prog_a, "user_prog_a");
   //process_execute(u_prog_b, "user_prog_b");
   while(1) {
      //console_put_str("Main ");
   };
   return 0;
}

/* 在线程中运行的函数 */
void k_thread_a(void* arg) {     
   char* para = arg;
   while(1) {
      console_put_str(" v_a");
      //console_put_int(test_var_a);
   }
}

/* 在线程中运行的函数 */
void k_thread_b(void* arg) {     
   char* para = arg;
   while(1) {
      console_put_str(" v_b");
      //console_put_int(test_var_b);
   }
}

/* 在线程中运行的函数 */
void k_thread_c(void* arg) {     
   char* para = arg;
   while(1) {
      console_put_str(" v_c");
      //console_put_int(test_var_b);
   }
}

void u_prog_a(void) {
   while(1) {
      test_var_a++;
   }
}


void u_prog_b(void) {
   while(1) {
      test_var_b++;
   }
}
