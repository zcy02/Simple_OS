#ifndef __KERNEL_MEMORY_H
#define __KERNEL_MEMORY_H
#include "stdint.h"
#include "bitmap.h"
#include "list.h"

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

// 内存块
struct mem_block {
    struct list_elem free_elem;
};

// 内存块描述符
struct mem_block_desc {
    uint32_t block_size; // 内存块大小
    uint32_t blocks_per_arena; // 本 arena 中可容纳此 mem_block 的数量
    struct list free_list; // 目前可用的 mem_block 链表
};

#define DESC_CNT 7 // 内存块描述符个数

extern struct pool kernel_pool, user_pool;
void mem_init(void);
void* kalloc(uint32_t pg_cnt);
void* malloc_page(enum pool_flags flag, uint32_t cnt);
uint32_t* pte_ptr(uint32_t vaddr);
uint32_t* pde_ptr(uint32_t vaddr);
uint32_t addr_v2p(uint32_t vaddr);
void* get_a_page(enum pool_flags pf, uint32_t vaddr);
void* get_user_pages(uint32_t pg_cnt);
void print_pool_usage(enum pool_flags flag);
#endif


