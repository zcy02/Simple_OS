#ifndef __KERNEL_MEMORY_H
#define __KERNEL_MEMORY_H
#include "stdint.h"
#include "bitmap.h"

/*PTE 及 PDE 属性操作*/
//Present
#define PAGE_P_1	1
#define PAGE_P_0	0
//Read/Write
#define PAGE_RW_R	0
#define PAGE_RW_W	2
//User/Supervisor
#define PAGE_US_S	0
#define PAGE_US_U	4

enum pool_flags {
	KERNEL = 1,
	USER = 2
};

/* 虚拟地址池，用于管理虚拟地址 */
struct virtual_addr {
	struct bitmap vaddr_bitmap;	// 虚拟地址用到的位图结构
	uint32_t vaddr_start;		// 虚拟地址起始地址
};

extern struct pool kernel_pool, user_pool;
void mem_init(void);
#endif


