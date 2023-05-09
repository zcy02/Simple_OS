#include "bitmap.h"
#include "stdint.h"
#include "string.h"
#include "print.h"
#include "interrupt.h"
#include "debug.h"

/* 将位图btmp初始化 */
void bitmap_init(struct bitmap* btmp) {
	memset(btmp->bits, 0, btmp->btmp_bytes_len);
	btmp->usage = 0;
}

/* 判断bit_idx位是否为1,若为1,返回true,否则返回false */
bool bitmap_scan_test(struct bitmap* btmp, uint32_t bit_idx) {
	uint32_t byte_idx = bit_idx / 8;	// 要操作位位置除以字节长度，获取所在字节的数组下标
	uint32_t bit_odd = bit_idx % 8;		// 操作位取余，获取其在字节的中位置
	return (btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd));	// 做与运算判断bit_idx位是否为1
}

/* 在位图中申请连续cnt个位，成功，返回其起始位下标，失败，返回-1 */
int bitmap_scan(struct bitmap* btmp, uint32_t cnt) {
	uint32_t idx_byte = 0;			// 记录空闲位所在的字节
/* 逐字节比较 */
	while ((0xff == btmp->bits[idx_byte]) && (idx_byte < btmp->btmp_bytes_len)) {
/* 1表示该位已分配，若为0xff，则表示该字节内已无空闲位，继续向下一个字节寻找 */
		idx_byte++;
	}

	ASSERT(idx_byte < btmp->btmp_bytes_len);	// 如果表达式为真，无事发生，表达式为假，弹框报错
	if (idx_byte == btmp->btmp_bytes_len) {		// 在内存池中找不到可用空间
		return -1;
	}

/* 如果在位图数组范围中的某个字节找到了空闲位
 * 在该字节内逐位比对，返回空闲位的索引 */
	int idx_bit = 0;
/* 和btmp->bits[idx_byte]这个字节逐位对比，找到空位在该字节的起始位置 */
	while ((uint8_t)(BITMAP_MASK << idx_bit) & btmp->bits[idx_byte]) {
		idx_bit++;
	}

	int bit_idx_start = idx_byte * 8 + idx_bit; 		// 空闲位所在位图的起始位置
/* 只需要一位的情况 */
	if (cnt == 1) {
		return bit_idx_start;
	}

	uint32_t bit_left = (btmp->btmp_bytes_len * 8 - bit_idx_start);		// 记录位图中还有多少位可以判断
	uint32_t next_bit = bit_idx_start + 1;
	uint32_t count = 1;					// 统计找到的空闲位个数
	
	bit_idx_start = -1;					// 先将其置为-1,若找不到连续的位就直接返回
	while (bit_left-- > 0) {
		if (!(bitmap_scan_test(btmp, next_bit))) {	// 如果next_bit为0,即下一位未被利用
			count++;				// 空闲位个数加1
		} else {
			count = 0;				// 下一位被使用，此处不存在连续个cnt位
		}
		if (count == cnt) {				// 成功找到了cnt个空位
			bit_idx_start = next_bit - cnt + 1;	// 记录连续空位的起始位置
			break;					
		}
		next_bit++;
	}

	return bit_idx_start;
}

/* 将位图btmp的bit_idx位设置为传入的value */
void bitmap_set(struct bitmap* btmp, uint32_t bit_idx, int8_t value) {
	ASSERT((value == 0) || (value == 1));
	uint32_t byte_idx = bit_idx / 8;			// 找到要操作的位所在的字节
	uint32_t bit_odd = bit_idx % 8;				// 找到要操作位在字节中的位置

/* BITMAP_MASK为0x1,对其进行移位操作后，与索引位进行逻辑操作 */
	if (value) {		      // 如果value为1
      //if (!(btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd))) {
         btmp->usage += 1;
      //}
      btmp->bits[byte_idx] |= (BITMAP_MASK << bit_odd);
      
   } else {		      // 若为0
      //if (btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd)) {
         btmp->usage -= 1;
      //}
      btmp->bits[byte_idx] &= ~(BITMAP_MASK << bit_odd);
   }
}







