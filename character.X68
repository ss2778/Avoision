*-----------------------------------------------------------
* Title      : Character
* Written by : Brandon Holtzman
* Date       : 10/6/24
* Description: Character 'class' for assembly game
*-----------------------------------------------------------
CHAR_SIZE                    EQU  22
CHAR_X_POS_OFFSET            EQU  0
CHAR_Y_POS_OFFSET            EQU  2
CHAR_FP_Y_POS_OFFSET         EQU  4
CHAR_Y_VEL_OFFSET            EQU  6
CHAR_LIFE_OFFSET             EQU  8
CHAR_HALF_HEIGHT_OFFSET      EQU  10
CHAR_HALF_WIDTH_OFFSET       EQU  12
CHAR_CENTER_X_OFFSET         EQU  14
CHAR_CENTER_Y_OFFSET         EQU  16
CHAR_ART_ADDR_OFFSET         EQU  18

CHAR_MOVE_SPEED              EQU  3
CHAR_W_KEY                   EQU  $57
CHAR_A_KEY                   EQU  $41
CHAR_D_KEY                   EQU  $44
CHAR_GET_USER_INPUT          EQU  19
CHAR_WIDTH_OFFSET            EQU  $12
CHAR_HEIGHT_OFFSET           EQU  $16
* CHAR_JUMP_SPEED is in 12.4 fixed point format
CHAR_JUMP_SPEED              EQU  $77

CHAR_START_X                 EQU  320
CHAR_START_Y                 EQU  240
CHAR_LIVES                   EQU  3
*---
* Creates an instance of the character
* 
* a1 - start address of filename
*
* out a0 - start address of character in memory
* out d0.b - 0 = success, non-zero = failure
*---
char_createChar:
.REGS  REG A2
    movem.l .REGS, -(sp)
    * Store file name
    move.l a1, a2
    * allocate memory for the character object
    move.l #CHAR_SIZE, d1
    bsr mem_Alloc
    tst.b d0
    bne .error
    move.l a2, a1
    move.l a0, a2
    * load the character art into memory
    bsr bmp_Load
    tst.b d0
    bne .error
    move.l a0, CHAR_ART_ADDR_OFFSET(a2)
    * initialize values
    move.w #CHAR_START_X, CHAR_X_POS_OFFSET(a2)
    move.w #CHAR_START_Y, CHAR_Y_POS_OFFSET(a2)
    move.w #0, CHAR_Y_VEL_OFFSET(a2)
    move.w #$F00, CHAR_FP_Y_POS_OFFSET(a2)
    move.w CHAR_WIDTH_OFFSET(a0), d0
    * divide by 2
    lsr.w #1, d0
    move.w d0, CHAR_HALF_WIDTH_OFFSET(a2)
    add.w #1, d0
    move.w d0, CHAR_CENTER_X_OFFSET(a2)
    move.w CHAR_HEIGHT_OFFSET(a0), d0
    * divide by 2
    lsr.w #1, d0
    move.w d0, CHAR_HALF_HEIGHT_OFFSET(a2)
    add.w #1, d0
    move.w d0, CHAR_CENTER_Y_OFFSET(a2)
    move.w #CHAR_LIVES, CHAR_LIFE_OFFSET(a2)
    move.l a2, a0
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+, .REGS
    rts




*---
* Resets the character values for the start of the game
* 
* a3 - start address of character
*
*---
char_resetChar:
    * reset values
    move.w #CHAR_START_X, CHAR_X_POS_OFFSET(a3)
    move.w #CHAR_START_Y, CHAR_Y_POS_OFFSET(a3)
    move.w #0, CHAR_Y_VEL_OFFSET(a3)
    move.w #$F00, CHAR_FP_Y_POS_OFFSET(a3)
    
    move.l  CHAR_ART_ADDR_OFFSET(a3), a0
    move.w CHAR_WIDTH_OFFSET(a0), d0
    * divide by 2 via left shift
    lsr.w #1, d0
    move.w d0, CHAR_HALF_WIDTH_OFFSET(a3)
    add.w #1, d0
    move.w d0, CHAR_CENTER_X_OFFSET(a3)
    move.w CHAR_HEIGHT_OFFSET(a0), d0
    * divide by 2 via left shift
    lsr.w #1, d0
    move.w d0, CHAR_HALF_HEIGHT_OFFSET(a3)
    add.w #1, d0
    move.w d0, CHAR_CENTER_Y_OFFSET(a3)
    move.w #CHAR_LIVES, CHAR_LIFE_OFFSET(a3)

    rts


*---
* Draws the background over the character's current position
* 
* a3 - start address of character to erase
* a2 - start address of the background image
*---   
char_erase:
.REGS  REG D2-D4
    movem.l .REGS, -(sp)
    * draw the background with a crop and position of the character's location
    move.l CHAR_ART_ADDR_OFFSET(a3), a0
    move.w CHAR_X_POS_OFFSET(a3), d1
    swap d1
    move.w CHAR_Y_POS_OFFSET(a3), d1
    move.l d1, d0
    move.l a2, a1
    move.w CHAR_WIDTH_OFFSET(a0), d2
    swap d2
    move.w CHAR_HEIGHT_OFFSET(a0), d2
    bsr bmp_Draw
    movem.l (sp)+, .REGS
    rts


*---
* Damages the character
* 
* a3 - start address of character
*
* out d0.b - 0 = stil alive, non-zero = loss reached
*---
char_dmg:
    * decrement the character's life value
    sub.w #1, CHAR_LIFE_OFFSET(a3)
    bsr sseg_drawLives
    
    move.b #0, d0
    * check for loss
    tst.w CHAR_LIFE_OFFSET(a3)
    bne .done
    * if the player is dead, raise loss flag
    move.b #1, d0
    
.done
    rts

*---
* Draws the background over the character's current position
* 
* a3 - start address of character to erase
*
*---   
char_draw:
.REGS  REG D2-D4
    movem.l .REGS, -(sp)
    * draw the background with a crop and position of the character's location
    move.l CHAR_ART_ADDR_OFFSET(a3), a1
    move.w CHAR_X_POS_OFFSET(a3), d1
    swap d1
    move.w CHAR_Y_POS_OFFSET(a3), d1
    move.l #0, d0
    move.w WIDTH_OFFSET(a1), d2
    swap d2
    move.w HEIGHT_OFFSET(a1), d2
    bsr bmp_Draw
    movem.l (sp)+, .REGS
    rts

*---
* Moves the character based on player input.
* Draws the character to their new position on screen.
* Left movement is prioritized over right movement.
* 
* a3 - start address of character to move
*
*---
char_Move:
.REGS  REG D2-D4
    movem.l .REGS, -(sp)
    * check what movement keys are pressed
    move.l #(CHAR_W_KEY<<16 + CHAR_A_KEY<<8 + CHAR_D_KEY), d1
    move.b #CHAR_GET_USER_INPUT, d0
    trap #15
    * compare result to immediates to determine inputs
    move.l d1, d2
    
    * get the character width
    move.l CHAR_ART_ADDR_OFFSET(a3), a0
    move.w CHAR_WIDTH_OFFSET(a0), d0
    * determine the right border of movement
    move.w #RIGHT_WALL, d3
    sub.w d0, d3
    move.w CHAR_X_POS_OFFSET(a3), d0
    * left movement check
    andi.l #$0000FF00, d2
    beq .postLeft
    * move character left
    sub.w #CHAR_MOVE_SPEED, d0
    * make sure the character is in bounds of the room
    cmp.w #LEFT_WALL, d0
    bgt .postMove
    move.w #LEFT_WALL, d0
    add.w #1, d0
    bra .postMove
.postLeft
    * right movement check
    move.l d1, d2
    andi.l #$000000FF, d2
    beq .postMove
    * move character right
    add.w #CHAR_MOVE_SPEED, d0
    * make sure the character is in bounds of the room
    cmp.w d3, d0
    ble .postMove
    move.w d3, d0
.postMove
    move.w d0, CHAR_X_POS_OFFSET(a3)
    * update center x position
    add.w CHAR_HALF_WIDTH_OFFSET(a3), d0
    add.w #1, d0
    move.w d0, CHAR_CENTER_X_OFFSET(a3)
    
    * check if the character is grounded
    * get the character height
    move.w CHAR_HEIGHT_OFFSET(a0), d0
    * calculate the grounded y position
    move.w #FLOOR, d3
    sub.w d0, d3
    cmp.w CHAR_Y_POS_OFFSET(a3), d3
    bne .gravity
    
    * check for a jump input
    move.l d1, d2
    andi.l #$00FF0000, d2
    beq .postJump
    * give the character vertical velocity
    move.w #CHAR_JUMP_SPEED, CHAR_Y_VEL_OFFSET(a3)
    bra .postJump
    * accelerates the character downward if they are not grounded
.gravity
    * subtract the gravity constant to the character velocity
    sub.w #GRAVITY, CHAR_Y_VEL_OFFSET(a3)
.postJump
    * update the character's position, adjusted for floating point math (12.4 format)
    move.w CHAR_FP_Y_POS_OFFSET(a3), d0
    sub.w CHAR_Y_VEL_OFFSET(a3), d0
    * check for floor collision
    lsl.w #4, d3
    cmp.w d3, d0
    blt .aboveFloor
    move.w d3, d0
    move.w #0, CHAR_Y_VEL_OFFSET(a3)
.aboveFloor
    move.w d0, CHAR_FP_Y_POS_OFFSET(a3)
    * add 1 to the first fractional bit and bitshift to round
    add.w #8, d0
    lsr.w #4, d0
    move.w d0, CHAR_Y_POS_OFFSET(a3)
    * update center y position
    add.w CHAR_HALF_HEIGHT_OFFSET(a3), d0
    add.w #1, d0
    move.w d0, CHAR_CENTER_Y_OFFSET(a3)
    movem.l (sp)+, .REGS
    rts











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
