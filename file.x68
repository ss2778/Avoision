*-----------------------------------------------------------
* Title      : File IO module
* Written by : Brandon Holtzman
* Date       : 9/18/24
* Description: File I/O  subroutines for sorting algorithm
*-----------------------------------------------------------

FILE_TASK_FOPEN      EQU     51
FILE_TASK_FCREATE    EQU     52
FILE_TASK_FREAD      EQU     53
FILE_TASK_FWRITE     EQU     54
FILE_TASK_FCLOSE     EQU     56

*---
* Write a buffer to a file
*
* a1 - start address of filename
* a2 - start address of buffer to write
* d1.l - size of buffer to write
*
* out d0.b - 0 for success, non-zero for failure
*---
file_Write:
.REGS   REG     D2
        * save d2
        movem.l .REGS, -(sp)
        * store value of d1 in d2
        move.l  d1, d2
        * open the file
        move.b  #FILE_TASK_FCREATE, d0
        trap    #15
        tst.w   d0
        bne     .error
        
        * write the words
        move.b  #FILE_TASK_FWRITE, d0
        move.l     a2, a1

        trap    #15
        tst.w   d0
        bne     .error
        
        * close the file
        move.l  #FILE_TASK_FCLOSE, d0
        trap    #15
        tst.w   d0
        beq     .done

.error
        move.b #1, d0
.done
        * restore d2
        movem.l (sp)+, .REGS
        rts

*---
* Read a buffer from a file
*
* a1 - start address of filename
* a2 - start address of buffer to read
* d1.l - size of buffer to read
*
* out d1.l - number of bytes read
* out d0.b - 0 for success, non-zero for failure
*---
file_Read:
.REGS   REG     D2
        * save d2
        movem.l .REGS, -(sp)
        * store value of d1 in d2
        move.l  d1, d2
        * open the file
        move.b  #FILE_TASK_FOPEN, d0
        trap    #15
        tst.w   d0
        bne     .error
        
        * read the words
        move.b  #FILE_TASK_FREAD, d0
        move.l     a2, a1

        trap    #15
        and.w #$FE, d0
        tst.w   d0
        bne     .error
        
        * close the file
        move.l  #FILE_TASK_FCLOSE, d0
        trap    #15
        tst.w   d0
        
        beq     .done


.error
        move.b #1, d0
.done
        * save the number of bytes read in d1
        move.l d2, d1
        * restore d2
        movem.l (sp)+, .REGS
        rts
    












*~Font name~Courier New~
*~Font size~14~
*~Tab type~1~
*~Tab size~4~
