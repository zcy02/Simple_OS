#include "console.h"
#include "dir.h"
#include "fs.h"
#include "init.h"
#include "interrupt.h"
#include "memory.h"
#include "print.h"
#include "process.h"
#include "stdio.h"
#include "syscall-init.h"
#include "syscall.h"
#include "thread.h"

void k_thread_a(void*);
void k_thread_b(void*);
void u_prog_a(void);
void u_prog_b(void);

int main(void) {
    put_str("I am kernel\n");
    init_all();
    intr_enable();  // 打开中断

    struct dir* p_dir = sys_opendir("/dirl");
    if (p_dir) {
        printf("/ open done!\ncontent:\n");
        char* type = NULL;
        struct dir_entry* dir_e = NULL;
        while ((dir_e = sys_readdir(p_dir))) {
            if (dir_e->f_type == FT_REGULAR) {
                type = "regular";
            } else {
                type = "directory";
            }
            printf(" %s %s\n", type, dir_e->filename);
        }
        if (sys_closedir(p_dir) == 0) {
            printf("/ close done!\n");
        } else {
            printf("/ close fail!\n");
        }
    } else {
        printf("/dirl/subdirl open fail!\n");
    }
    struct stat obj_stat;
    sys_stat("/", &obj_stat);
    printf("/`s info\n   i_no:%d\n   size:%d\n   filetype:%s\n",
           obj_stat.st_ino, obj_stat.st_size,
           obj_stat.st_filetype == 2 ? "directory" : "regular");
    sys_stat("/dirl", &obj_stat);
    printf("/dirl`s info\n   i_no:%d\n   size:%d\n   filetype:%s\n",
           obj_stat.st_ino, obj_stat.st_size,
           obj_stat.st_filetype == 2 ? "directory" : "regular");

    while (1)
        ;
    return 0;
}
/* 在线程中运行的函数 */
void k_thread_a(void* arg) {
    void* addr1 = sys_malloc(256);
    void* addr2 = sys_malloc(255);
    void* addr3 = sys_malloc(254);
    console_put_str(" thread_a malloc addr:0x");
    console_put_int((int)addr1);
    console_put_char(',');
    console_put_int((int)addr2);
    console_put_char(',');
    console_put_int((int)addr3);
    console_put_char('\n');

    int cpu_delay = 100000;
    while (cpu_delay-- > 0)
        ;
    sys_free(addr1);
    sys_free(addr2);
    sys_free(addr3);
    while (1)
        ;
}

/* 在线程中运行的函数 */
void k_thread_b(void* arg) {
    void* addr1 = sys_malloc(256);
    void* addr2 = sys_malloc(255);
    void* addr3 = sys_malloc(254);
    console_put_str(" thread_b malloc addr:0x");
    console_put_int((int)addr1);
    console_put_char(',');
    console_put_int((int)addr2);
    console_put_char(',');
    console_put_int((int)addr3);
    console_put_char('\n');

    int cpu_delay = 100000;
    while (cpu_delay-- > 0)
        ;
    sys_free(addr1);
    sys_free(addr2);
    sys_free(addr3);
    while (1)
        ;
}

void u_prog_a(void) {
    void* addr1 = malloc(256);
    void* addr2 = malloc(255);
    void* addr3 = malloc(254);
    printf(" prog_a malloc addr:0x%x, 0x%x, 0x%x\n", (int)addr1, (int)addr2, (int)addr3);
    int cpu_delay = 100000;
    while (cpu_delay-- > 0)
        ;
    free(addr1);
    free(addr2);
    free(addr3);
    while (1)
        ;
}

void u_prog_b(void) {
    void* addr1 = malloc(256);
    void* addr2 = malloc(255);
    void* addr3 = malloc(254);
    printf(" prog_b malloc addr:0x%x, 0x%x, 0x%x\n", (int)addr1, (int)addr2, (int)addr3);
    int cpu_delay = 100000;
    while (cpu_delay-- > 0)
        ;
    free(addr1);
    free(addr2);
    free(addr3);
    while (1)
        ;
}