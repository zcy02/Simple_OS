#ifndef __USERPROG_TSS_H
#define __USERPROG_TSS_H
#include "thread.h"
#include "stdint.h"
#include "global.h"
#include "string.h"
#include "print.h"
void update_tss_esp(struct task_struct* pthread);
void tss_init(void);
#endif