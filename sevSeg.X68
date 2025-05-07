*-----------------------------------------------------------
* Title      : Seven Segment
* Written by : Brandon Holtzman
* Date       : 10/14/2024
* Description: Seven segment display code for assembly game
*-----------------------------------------------------------
SSEG_DRAW_LINE             EQU  84


SSEG_A_SEG                 EQU  1<<0
SSEG_B_SEG                 EQU  1<<1
SSEG_C_SEG                 EQU  1<<2
SSEG_D_SEG                 EQU  1<<3
SSEG_E_SEG                 EQU  1<<4
SSEG_F_SEG                 EQU  1<<5
SSEG_G_SEG                 EQU  1<<6


SSEG_PEN_COLOR             EQU  80
SSEG_PEN_WHITE             EQU  $00FFFFFF
SSEG_PEN_BLACK             EQU  0

SSEG_SCORE_LEFT_X          EQU  480
SSEG_LIVES_LEFT_X          EQU  80
SSEG_TOP_Y                 EQU  404
SSEG_LINE_LENGTH           EQU  32
SSEG_DIGIT_DISTANCE        EQU  8

*---
* Initialize 7 segment displays
* 
* a3 - character object address
* 
*---
sseg_init:
    * initialize both values
    move.l #0, SSEG_SCORE
    
    * call both draw functions
    move.l #0, d0
    bsr sseg_drawScore
    bsr sseg_drawLives
    rts
    
*---
* Draw a single digit at the specified position
* 
* d0 - digit to draw
* d5 - X position of digit position
* 
*---
sseg_drawDigit:
.REGS  REG D2-D7/A2
    movem.l .REGS, -(sp)
    * load the appropriate digit bitfield
    lea SSEG_ARRAY, a2
    move.b (a2, d0), d7
    * load the highest y position of the digit
    move.w #SSEG_TOP_Y, d6
    
    * check and draw each segment
    * if it is active, draw it with a white pen color
    * if inactive, draw it with a black pen color
    
    * check A segment
    btst #0, d7
    bne .Awhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Adraw
.Awhite
    move.l #SSEG_PEN_WHITE, d1
.Adraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set A segment parameters
    move.w d5, d1
    move.w d5, d3
    add.w #SSEG_LINE_LENGTH, d3
    move.w d6, d2
    move.w d6, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    * check B segment
    btst #1, d7
    bne .Bwhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Bdraw
.Bwhite
    move.l #SSEG_PEN_WHITE, d1
.Bdraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set B segment parameters
    move.w d5, d1
    add.w #SSEG_LINE_LENGTH, d1
    move.w d5, d3
    add.w #SSEG_LINE_LENGTH, d3
    move.w d6, d2
    add.w #1, d2
    move.w d6, d4
    add.w #SSEG_LINE_LENGTH+1, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    * check C segment
    btst #2, d7
    bne .Cwhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Cdraw
.Cwhite
    move.l #SSEG_PEN_WHITE, d1
.Cdraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set C segment parameters
    move.w d5, d1
    add.w #SSEG_LINE_LENGTH, d1
    move.w d5, d3
    add.w #SSEG_LINE_LENGTH, d3
    move.w d6, d2
    add.w #SSEG_LINE_LENGTH+3, d2
    move.w d6, d4
    add.w #(SSEG_LINE_LENGTH*2)+3, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    * check D segment
    btst #3, d7
    bne .Dwhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Ddraw
.Dwhite
    move.l #SSEG_PEN_WHITE, d1
.Ddraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set D segment parameters
    move.w d5, d1
    move.w d5, d3
    add.w #SSEG_LINE_LENGTH, d3
    move.w d6, d2
    add.w #(SSEG_LINE_LENGTH*2)+4, d2
    move.w d6, d4
    add.w #(SSEG_LINE_LENGTH*2)+4, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    * check E segment
    btst #4, d7
    bne .Ewhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Edraw
.Ewhite
    move.l #SSEG_PEN_WHITE, d1
.Edraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set E segment parameters
    move.w d5, d1
    move.w d5, d3
    move.w d6, d2
    add.w #SSEG_LINE_LENGTH+3, d2
    move.w d6, d4
    add.w #(SSEG_LINE_LENGTH*2)+3, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    * check F segment
    btst #5, d7
    bne .Fwhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Fdraw
.Fwhite
    move.l #SSEG_PEN_WHITE, d1
.Fdraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set F segment parameters
    move.w d5, d1
    move.w d5, d3
    move.w d6, d2
    add.w #1, d2
    move.w d6, d4
    add.w #SSEG_LINE_LENGTH+1, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    * check G segment
    btst #6, d7
    bne .Gwhite
    move.l #SSEG_PEN_BLACK, d1
    bra .Gdraw
.Gwhite
    move.l #SSEG_PEN_WHITE, d1
.Gdraw
    * set color
    move.l #SSEG_PEN_COLOR, d0
    trap #15
    * set G segment parameters
    move.w d5, d1
    move.w d5, d3
    add.w #SSEG_LINE_LENGTH, d3
    move.w d6, d2
    add.w #SSEG_LINE_LENGTH+2, d2
    move.w d6, d4
    add.w #SSEG_LINE_LENGTH+2, d4
    move.l #SSEG_DRAW_LINE, d0
    trap #15
    
    movem.l (sp)+, .REGS
    rts

*---
* update the lives display
* 
* a3 - character object address
* 
*---
sseg_drawLives:
    * read the number of lives from the character object
    move.w CHAR_LIFE_OFFSET(a3), d0
    move.w #SSEG_LIVES_LEFT_X, d5
    bsr sseg_drawDigit
    rts


*---
* update the score display
* supports numbers with 1-3 digits
* 
* d0 - amount to increment the score
* 
*---
sseg_drawScore:
.REGS  REG D2
    movem.l .REGS, -(sp)
    add.l d0, SSEG_SCORE
    
    * draw the first digit of the score
    move.l SSEG_SCORE, d2
    divu #10, d2
    swap d2
    move.w d2, d0
    move.w #SSEG_SCORE_LEFT_X, d5
    bsr sseg_drawDigit
    * draw the second digit of the score
    move.w #0, d2
    swap d2
    divu #10, d2
    swap d2
    move.w d2, d0
    sub.w #SSEG_LINE_LENGTH+SSEG_DIGIT_DISTANCE, d5
    bsr sseg_drawDigit
    * draw the third digit of the score
    move.l SSEG_SCORE, d2
    divu #100, d2
    move.w d2, d0
    sub.w #SSEG_LINE_LENGTH+SSEG_DIGIT_DISTANCE, d5
    bsr sseg_drawDigit
    
    movem.l (sp)+, .REGS
    rts


    ds.w 0
SSEG_SCORE    ds.l  1

SSEG_ARRAY

SSEG_ZERO     dc.b  SSEG_A_SEG|SSEG_B_SEG|SSEG_C_SEG|SSEG_D_SEG|SSEG_E_SEG|SSEG_F_SEG
SSEG_ONE      dc.b  SSEG_B_SEG|SSEG_C_SEG
SSEG_TWO      dc.b  SSEG_A_SEG|SSEG_B_SEG|SSEG_D_SEG|SSEG_E_SEG|SSEG_G_SEG
SSEG_THREE    dc.b  SSEG_A_SEG|SSEG_B_SEG|SSEG_C_SEG|SSEG_D_SEG|SSEG_G_SEG
SSEG_FOUR     dc.b  SSEG_B_SEG|SSEG_C_SEG|SSEG_F_SEG|SSEG_G_SEG
SSEG_FIVE     dc.b  SSEG_A_SEG|SSEG_C_SEG|SSEG_D_SEG|SSEG_F_SEG|SSEG_G_SEG
SSEG_SIX      dc.b  SSEG_A_SEG|SSEG_C_SEG|SSEG_D_SEG|SSEG_E_SEG|SSEG_F_SEG|SSEG_G_SEG
SSEG_SEV      dc.b  SSEG_A_SEG|SSEG_B_SEG|SSEG_C_SEG
SSEG_EIGHT    dc.b  SSEG_A_SEG|SSEG_B_SEG|SSEG_C_SEG|SSEG_D_SEG|SSEG_E_SEG|SSEG_F_SEG|SSEG_G_SEG
SSEG_NINE     dc.b  SSEG_A_SEG|SSEG_B_SEG|SSEG_C_SEG|SSEG_D_SEG|SSEG_F_SEG|SSEG_G_SEG

    ds.w 0
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
