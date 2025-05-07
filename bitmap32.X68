*-----------------------------------------------------------
* Title      : Bitmap Subroutines
* Written by : Brandon Holtzman
* Date       : 9/25/24
* Description: Bitmap Subroutines
*-----------------------------------------------------------
BMP_FILE_BUFFER                     EQU     $12C0FF
BMP_PEN_COLOR_TRAP_CODE             EQU     80
BMP_DRAW_PIXEL_TRAP_CODE            EQU     82
BMP_SIZE_LIMIT                      EQU     1024
BMP_TYPE_OFFSET                     EQU     $1C
BMP_DATA_OFFSET_OFFSET              EQU     $A
BMP_WIDTH_OFFSET                    EQU     $12
BMP_HEIGHT_OFFSET                   EQU     $16
BMP_BMP_SIGNATURE                   EQU     $424D

    


*---
* Loads a bitmap into memory
* 
* a1 - start address of filename
*
* out a0 - start address of bitmap in memory
* out d0.b - 0 = success, non-zero = failure
*---
bmp_Load:
.REGS  REG D2-D3/A2
    movem.l .REGS, -(sp)
    * store the name of the file in a non-volatile register
    move.l a1, a2
    * allocate memory in the heap for the file buffer
    move.l #BMP_FILE_BUFFER, d1
    bsr mem_alloc
    tst.b d0
    bne .error
    * read the file data into the buffer
    move.l a2, a1
    move.l a0, a2
    move.l #BMP_FILE_BUFFER, d1
    bsr file_Read
    tst.b d0
    bne .error
    move.l d1, d2
    * Check the data to ensure it is a bitmap
    cmp.w #BMP_BMP_SIGNATURE, (a2)
    bne .free
    * Check to make sure it meets the size restrictions
    move.w BMP_WIDTH_OFFSET(a1), d3
    rol.w #8, d3
    cmp.w #BMP_SIZE_LIMIT, d3
    bgt .free
    move.w BMP_HEIGHT_OFFSET(a1), d4
    rol.w #8, d4
    cmp.w #BMP_SIZE_LIMIT, d4
    bgt .free
    move.b #0, d0
    * reorder the height and width
    move.w d3, BMP_WIDTH_OFFSET(a1)
    move.w d4, BMP_HEIGHT_OFFSET(a1)
    * if it is a 32 bit bitmap, reorder the bits
    move.b BMP_TYPE_OFFSET(a1), d1
    
    * find end address of data
    move.l a1, a2
    add.l d2, a2
    * move address to start of data
    move.l BMP_DATA_OFFSET_OFFSET(a1), d0
    rol.l #8, d0
    add.l d0, a1
    
.reorderLoop
    
    move.l (a1), d1
    and #$FF00, d1
    ror.l #8, d1
    move.l d1, (a1)+
    * check for end of loop
    cmp.l a2, a1
    blt .reorderLoop
    * check if all values have been rewritten
    
    move.b #0, d0
    bra .done
.free
    * Free the allocated memory
    move.l a2, a1
    bsr mem_Free
.error
    move.b #1, d0
.done
    movem.l (sp)+, .REGS
    rts


*---
* Frees the memory associated with the bitmap
* 
* a1 - start address of bitmap in memory
*
* out d0.b - 0 = success, non-zero = failure
*---
bmp_Unload:
    * free the memory and verify success
    bsr mem_free
    tst.b d0
    bne .error
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    rts

*---
* Draws the specified portion of the given bitmap
* 
* a1 - start address of bitmap in memory
* d0 - upper 16 bits: x offset of top left corner of crop
* d0 - lower 16 bits: y offset of top left corner of crop
* d1 - upper 16 bits: x offset of top left corner of target point
* d1 - lower 16 bits: y offset of top left corner of target point
* d2 - upper 16 bits: width of image to print
* d2 - lower 16 bits: height of image to print
* 
* out d0.b - 0 = success, non-zero = failure
*---
bmp_Draw:
.REGS   REG     D2-D7/A2-A6
    * store registers
    movem.l .REGS, -(sp)
    * store target point coordinates
    move.w d1, a3
    swap d1
    move.w d1, a2
    * store crop target point
    move.w d0, a4
    swap d0
    move.w d0, a0
    * store dimensions of image to print
    move.w d2, a6
    swap d2
    move.w d2, a5
    * store the width and height of the image
    move.l #0, d3
    move.l #0, d4
    move.w BMP_WIDTH_OFFSET(a1), d3
    move.w BMP_HEIGHT_OFFSET(a1), d4
    
    * 32 bit bitmap drawing
    * set memory offset variable
    move.l #0, d6
    move.w d4, d6
    sub.w a4, d6
    sub.w a6, d6
    mulu d3, d6
    add.w a0, d6
    lsl.l #2, d6
    move.l BMP_DATA_OFFSET_OFFSET(a1), d5
    rol.l #8, d5
    add.l d5, d6
    add.l d6, a1
    * set starting x and y positions
    move.w a6, d2
    sub.w #1, d2
    add.w a3, d2
    move.w a2, d7
    * determine new line address offset
    sub.w a5, d3
    lsl.l #2, d3
    
    * set ending x and y borders
    add.w d7, a5
    move.w a3, d4

    * iterate over pixels and draw them
.drawLoop32
    move.l (a1)+, d1
    * increment address offset
    * next iteration if pen is out of bounds
    move.l #BMP_PEN_COLOR_TRAP_CODE, d0
    trap #15
    move.l #BMP_DRAW_PIXEL_TRAP_CODE, d0
    * transfer x position into d1
    move.w d7, d1
    trap #15
    * increment (and check) width
    add.w #1, d7
    cmp.w a5, d7
    blt .drawLoop32
    * reset x position
    move.w a2, d7
    * increment address offset appropriately
    add.l d3, a1
    * decrement (and check) height
    sub.w #1, d2
    cmp.w d4, d2
    bge .drawLoop32
.done
    movem.l (sp)+, .REGS
    rts

        ds.w 0














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
