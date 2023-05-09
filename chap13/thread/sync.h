#ifndef __THREAD_SYNC_H 
#define __THREAD_SYNC_H 
#include "list.h" 
#include "stdint.h" 
#include "thread.h"

// 信号量结构
struct semaphore {
    uint8_t value; // 为 0 时表示没有锁，为 1 时表示有锁可取
    struct list waiters; // 线程阻塞队列
};

// 锁结构
struct lock {
    struct task_struct* holder; // 锁的持有者
    struct semaphore semaphore; // 用二元信号量实现锁
    uint32_t holder_repeat_nr;  // 锁的持有者重复申请锁的次数
};

void sema_init(struct semaphore* psema, uint8_t value); 
void sema_down(struct semaphore* psema);
void sema_up(struct semaphore* psema);
void lock_init(struct lock* plock);
void lock_acquire(struct lock* plock);
void lock_release(struct lock* plock);

#endif
