*-----------------------------------------------------------
* Title      : Memory management module
* Written by : Brandon Holtzman
* Date       : 9/23/24
* Description: Memory Management module subroutines
*-----------------------------------------------------------

* constants for callers of mem_Audit
MEM_AUDIT_OFFS_FREE_CNT     EQU 0
MEM_AUDIT_OFFS_USED_CNT     EQU 4
MEM_AUDIT_OFFS_FREE_MEM     EQU 8
MEM_AUDIT_OFFS_USED_MEM     EQU 12
MEM_AUDIT_RETURN_SIZE       EQU 16

* constants for header struct (internal)
MEM_SIZE        EQU 0
MEM_NEXT_ADDR   EQU 4
MEM_USED        EQU 8
MEM_HEADER_SIZE EQU 10 * !!! update this value based on your header layout

*---
* Initializes the start of the heap
* 
* a1 - start address of heap
* d1.l - size of heap
*
* out d0.b - 0 = success, non-zero = failure
*---
mem_InitHeap:
    * check if the heap size is sufficient
    * 11 for header and 1 byte
    cmp.l #11, d1
    blt .error
    
    move.l d1, d0
    * calculate and set next address (end of heap)
    move.l a1, a0
    add.l d0, a0
    move.l a0, MEM_NEXT_ADDR(a1)
    sub.l #1, a0
    move.l a0, MEM_HEAP_END
    * set size value properly for header and store it
    
    sub.l #MEM_HEADER_SIZE, d0
    move.l d0, MEM_SIZE(a1)
    
    * set free flag
    move.w #0, MEM_USED(a1)
    
    * set success flag
    move.b #0, d0
    
    * Store memory data
    move.l a1, MEM_HEAP_START
    
    bra .done
    
    * error if given buffer is too small
.error
    move.b #1, d0
.done    
    rts

*---
* Accumulates some statistics for memory usage
*
* out d0.b - 0 = success, non-zero = error
* out (sp) - count of free blocks
* out (sp+4) - count of used blocks
* out (sp+8) - total remaining free memory   d0
* out (sp+12) - total allocated memory       d1
mem_Audit:
    * verify the heap has been allocated
    move.l MEM_HEAP_START, d0
    move.l MEM_HEAP_END, d1
    cmp.l d1, d0
    beq .error
    * prepare initial values
    move.l MEM_HEAP_START, a0
    move.l #0, 4(sp)
    move.l #0, 8(sp)
    move.l #0, d0
    move.l #0, d1
    * iterate through blocks
.checkBlock
    * check memory is still valid
    cmp.l MEM_HEAP_END, a0
    bgt .done
    * check if block is free or used
    tst.w MEM_USED(a0)
    beq .free
    
    * used block processing
    * increment used block count
    add.l #1, 8(sp)
    
    * add the size of the block to the used mem total
    add.l MEM_SIZE(a0), d1
    bra .nextBlock
    
    * free block processing
.free
    * increment free block count
    add.l #1, 4(sp)
    
    * add the size of the block to the free mem total
    add.l MEM_SIZE(a0), d0
    
    *move a0 to next block
.nextBlock
    move.l MEM_NEXT_ADDR(a0), a0
    bra .checkBlock
.done
    * push values to the stack
    move.l d0, 12(sp)
    move.l d1, 16(sp)
    move.b #0, d0
    rts
    
.error
    * set error flag and return
    move.b #1, d0
    rts
          
*---
* Allocates a chunk of memory from the heap
*
* d1.l - size
*
* out a0 - start address of allocation
* out d0.b - 0 = success, non-zero = failure
*---
mem_Alloc:
.REGS  REG d2/a2
    movem.l .REGS, -(sp)
    * verify the heap has been allocated
    move.l MEM_HEAP_START, d0
    move.l MEM_HEAP_END, d2
    cmp.l d2, d0
    beq .error
    * iterate through the heap until a large enough free block is found
    move.l MEM_HEAP_START, a0
.blockSearch
    * check if block is used
    move.w MEM_USED(a0), d0
    tst.w d0
    bne .notValid
    * if free, check if block is large enough to store data
    cmp.l MEM_SIZE(a0), d1
    bgt .notValid
    bra .alloc
    
.notValid
    * increase a0 to next header
    move.l MEM_NEXT_ADDR(a0), a0
    * ensure a0 is still in valid memory
    cmp.l MEM_HEAP_END, a0
    bgt .error
    bra .blockSearch
    
* allocate memory
.alloc
    * check if the size is odd
    move.l d1, d2
    and.l #1, d2
    tst.l d2
    beq .even
    * if d1 is odd, add 1 to d1
    add.l #1, d1
.even
    * check if there is enough space for a header and data after this block
    move.l a0, a1
    add.l d1, a1
    move.l MEM_SIZE(a0), d2
    sub.l d1, d2
    * Check if there is enough space for at least 1 header and 1 word/2 bytes
    cmp.l #12, d2
    blt .noHead
    
    * allocate memory with a header at the end
    
    * update current header
    * store previous size
    move.l MEM_SIZE(a0), d2
    * update to new size
    move.l d1, MEM_SIZE(a0)
    * store previous next address field
    move.l MEM_NEXT_ADDR(a0), a2
    * find and store new 'tail' header address
    move.l a0, a1
    add.l d1, a1
    add.l #MEM_HEADER_SIZE, a1
    move.l a1, MEM_NEXT_ADDR(a0)
    * set block to used
    move.w #1, MEM_USED(a0)
    * set next tail header's fields
    * calculate new size for next header
    sub.l #MEM_HEADER_SIZE, d2
    sub.l d1, d2
    move.l d2, MEM_SIZE(a1)
    * store next value for new header
    move.l a2, MEM_NEXT_ADDR(a1)
    * set used flag to free
    move.w #0, MEM_USED(a1)
    move.b #0, d0
    * return address of allocation
    add.l #MEM_HEADER_SIZE, a0
    bra .done
    * allocate a block with no header at the end
    * also extends block to end of available heap memory
.noHead
    * update size to extend to border
    move.l MEM_NEXT_ADDR(a0), d2
    sub.l a0, d2
    sub.l #MEM_HEADER_SIZE, d2
    move.l d2, d1
    * update header
    * update to new size
    move.l d1, MEM_SIZE(a0)
    * set block to used
    move.w #1, MEM_USED(a0)
    move.b #0, d0
    * return address of allocation
    add.l #MEM_HEADER_SIZE, a0
    bra .done
    
.error
    move.b #1, d0
    
.done
    movem.l (sp)+, .REGS
    rts
    
*---
* Frees a chunk of memory from the heap
*
* a1 - start address of allocation
*
* out d0.b - 0 = success, non-zero = failure
*---
mem_Free:
    * verify the heap has been allocated
    move.l MEM_HEAP_START, d0
    move.l MEM_HEAP_END, d2
    cmp.l d2, d0
    beq .error
    sub.l #10, a1
    move.w #0, MEM_USED(a1)
    move.b #0, d0
    bra .done
    
.error
    move.b #1, d0
.done
    rts
    
*---
* Reduces a current memory allocation to a smaller number of bytes
*
* a1 - start address of allocation
* d1.l - new size
* 
* out d0.b - 0 = success, non-zero = failure
mem_Shrink:
    rts
    
    
MEM_HEAP_START dcb.l 1,$DEADEAD
MEM_HEAP_END   dcb.l 1,$DEADEAD









*~Font name~Courier New~
*~Font size~14~
*~Tab type~1~
*~Tab size~4~
