*-----------------------------------------------------------
* Title      : Bullet
* Written by : Brandon Holtzman
* Date       : 10/13/2024
* Description: Bullet 'class' for assembly game
*-----------------------------------------------------------
BULL_SIZE            EQU   20
BULL_ACTIVE_OFFSET   EQU   0
* Bullet type 0 is a laser bullet
* bullet type 1 is a bouncing bullet
BULL_TYPE_OFFSET     EQU   2
BULL_X_POS_OFFSET    EQU   4
BULL_X_VEL_OFFSET    EQU   6
BULL_Y_POS_OFFSET    EQU   8
BULL_FP_Y_POS_OFFSET EQU   10
BULL_Y_VEL_OFFSET    EQU   12
BULL_START_OFFSET    EQU   14
BULL_CENTER_X_OFFSET EQU   16
BULL_CENTER_Y_OFFSET EQU   18

BULL_WIDTH_OFFSET    EQU  $12
BULL_HEIGHT_OFFSET   EQU  $16

BULL_DIMENSION       EQU   7
BULL_HALF_DIMENSION  EQU   3
BULL_MAX_SPEED       EQU   3
BULL_MIN_SPEED       EQU   1

BULL_GET_TIME        EQU   8


*---
* Creates a bullet list buffer in memory
* 
* d0 - max number of bullets
* a4 - address of bullet filename
* out a0 - start address of bullet list
* out d0.b - 0 = success, non-zero = failure
*---
bull_createBulletList:
.REGS  REG D2/A2
    movem.l .REGS, -(sp)
    * find the number of bytes to allocate
    move.l #BULL_SIZE, d1
    mulu d0, d1
    move.l d1, d2
    * allocate the memory
    bsr mem_Alloc
    tst.b d0
    bne .error
    
    * set every bullet to inactive
    move.l a0, a1
    move.l a0, a2
    add.l a0, d2
.inactLoop
    move.w #0, BULL_ACTIVE_OFFSET(a1)
    add.l #BULL_SIZE, a1
    * check if end of list has been reached
    cmp.l d2, a1
    blt .inactLoop
    
    * seed the random number generator
    * This code is shamelessly recycled from Jeremy's RandomNumbers.x68 file

    move.b #BULL_GET_TIME, d0
    trap #15
    move.l d1, BULL_RANDOMVAL
    
    * load the bullet bitmap and store the address in BULL_ART_ADDR label
    move.l a4, a1
    bsr bmp_Load
    tst.b d0
    bne .error
    move.l a0, BULL_ART_ADDR
    * restore list address to output register
    move.l a2, a0
    
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+, .REGS
    rts

*---
* Erases all active bullets
* 
* d2 - max number of bullets
* a4 - bullet list start address
* a2 - address of background
*
*---
bull_eraseBullets:
.REGS  REG D2-D3/A3
    movem.l .REGS, -(sp)
    move.l #BULL_SIZE, d1
    move.l d2, d0
    mulu d0, d1
    move.l d1, d3
    
    move.l a4, a3
    add.l a4, d3
.searchLoop
    move.w BULL_ACTIVE_OFFSET(a3), d1
    tst.w d1
    bne .activeFound
.returnToLoop
    add.l #BULL_SIZE, a3
    * check if end of list has been reached
    cmp.l d3, a3
    blt .searchLoop
    bra .done

    * erase the active bullet
.activeFound
    move.w BULL_X_POS_OFFSET(a3), d1
    swap d1
    move.w BULL_Y_POS_OFFSET(a3), d1
    move.l d1, d0
    move.l a2, a1
    move.w #BULL_DIMENSION, d2
    swap d2
    move.w #BULL_DIMENSION, d2
    bsr bmp_Draw
    bra .returnToLoop
    
.done
    movem.l (sp)+, .REGS
    rts
    

*---
* Deactivate every bullet
* 
* d2 - max number of bullets
* a4 - bullet list start address
*
*---
bull_destroy:
.REGS  REG D3/A2
    movem.l .REGS, -(sp)
    move.l #BULL_SIZE, d1
    move.l d2, d0
    mulu d0, d1
    move.l d1, d3
    
    move.l a4, a2
    add.l a4, d3
.searchLoop
    move.w BULL_ACTIVE_OFFSET(a2), d1
    tst.w d1
    bne .activeFound
.returnToLoop
    add.l #BULL_SIZE, a2
    * check if end of list has been reached
    cmp.l d3, a2
    blt .searchLoop
    move.b #0, d0
    bra .done

    * deactivate the bullet
.activeFound
    move.w #0, BULL_ACTIVE_OFFSET(a2)
    bra .returnToLoop

.done
    movem.l (sp)+, .REGS
    rts
    
*---
* Check if active bullets have collided with the player
* 
* d2 - max number of bullets
* a4 - bullet list start address
* a3 - character object address
*
*---
bull_checkHit:
.REGS  REG D2-D3/A2
    movem.l .REGS, -(sp)
    move.l #BULL_SIZE, d1
    move.l d2, d0
    mulu d0, d1
    move.l d1, d3
    
    move.l a4, a2
    add.l a4, d3
.searchLoop
    move.w BULL_ACTIVE_OFFSET(a2), d1
    tst.w d1
    bne .activeFound
.returnToLoop
    add.l #BULL_SIZE, a2
    * check if end of list has been reached
    cmp.l d3, a2
    blt .searchLoop
    move.b #0, d0
    bra .done

    * check for collision with the character
.activeFound
    move.l #0, d2
    * check distance in the x direction
    move.w BULL_CENTER_X_OFFSET(a2), d2
    sub.w CHAR_CENTER_X_OFFSET(a3), d2
    * ensure the value is non negative
    cmp.w #0, d2
    bgt .nonNegX
    neg.w d2
.nonNegX
    * check distance between the centers
    sub.w CHAR_HALF_WIDTH_OFFSET(a3), d2
    sub.w #BULL_HALF_DIMENSION, d2
    * if it is non-negative, the boxes are not colliding
    cmp.w #0, d2
    bge .returnToLoop
    
    * check distance in the y direction
    move.w BULL_CENTER_Y_OFFSET(a2), d2
    sub.w CHAR_CENTER_Y_OFFSET(a3), d2
    * ensure the value is non negative
    cmp.w #0, d2
    bgt .nonNegY
    neg.w d2
.nonNegY
    sub.w CHAR_HALF_HEIGHT_OFFSET(a3), d2
    sub.w #BULL_HALF_DIMENSION, d2
    * if it is non-negative, the boxes are not colliding
    cmp.w #0, d2
    bge .returnToLoop
    
    * if no branch was taken, the current bullet and the player have collided
    * deal damage to the player
    bsr char_dmg
    * check if the player died
    tst.b d0
    bne .done
    
    move.w #0, BULL_ACTIVE_OFFSET(a2)
    bra .returnToLoop
.done
    movem.l (sp)+, .REGS
    rts    
    

*---
* Draws all active bullets
* 
* d2 - max number of bullets
* a4 - bullet list start address
*
*---
bull_drawBullets:
.REGS  REG D2-D3/A3
    movem.l .REGS, -(sp)
    move.l #BULL_SIZE, d1
    move.l d2, d0
    mulu d0, d1
    move.l d1, d3
    
    move.l a4, a3
    add.l a4, d3
.searchLoop
    move.w BULL_ACTIVE_OFFSET(a3), d1
    tst.w d1
    bne .activeFound
.returnToLoop
    add.l #BULL_SIZE, a3
    * check if end of list has been reached
    cmp.l d3, a3
    blt .searchLoop
    bra .done

    * draw the active bullet
.activeFound
    move.l BULL_ART_ADDR, a1
    move.w BULL_X_POS_OFFSET(a3), d1
    swap d1
    move.w BULL_Y_POS_OFFSET(a3), d1
    move.l #0, d0
    move.w #BULL_DIMENSION, d2
    swap d2
    move.w #BULL_DIMENSION, d2
    bsr bmp_Draw
    bra .returnToLoop
.done
    movem.l (sp)+, .REGS
    rts

*---
* Move the bullets according to their type and direction
* Also checks for wall collisions, returning any points gained
* Bisables bullets that collide with the wall 
*
* d2 - max number of bullets
* a4 - bullet list start address
*
* out d0 - number of points scored
*---
bull_move:
.REGS  REG D2-D4/A2-A3
    movem.l .REGS, -(sp)
    move.l #BULL_SIZE, d1
    move.l d2, d0
    mulu d0, d1
    move.l d1, d3
    
    move.l #0, d0
    
    move.l a4, a3
    add.l a4, d3
.searchLoop
    move.w BULL_ACTIVE_OFFSET(a3), d1
    tst.w d1
    bne .activeFound
.returnToLoop
    add.l #BULL_SIZE, a3
    * check if end of list has been reached
    cmp.l d3, a3
    blt .searchLoop
    bra .done
    
    * move the active bullet
.activeFound
    move.l #0, d2
    * check the direction the bullet is moving
    move.w BULL_START_OFFSET(a3), d2
    tst.w d2
    bne .moveRight
    * adjust its position accordingly
    
    * move the bullet to the left
    move.w BULL_X_VEL_OFFSET(a3), d2
    sub.w d2, BULL_X_POS_OFFSET(a3)
    * move the bullet center x
    sub.w d2, BULL_CENTER_X_OFFSET(a3)
    
    * check for left wall collision
    cmp.w #LEFT_WALL, BULL_X_POS_OFFSET(a3)
    bgt .bounceCheck
    * if the bullet collides, disable it and give the user a point
    move.w #0, BULL_ACTIVE_OFFSET(a3)
    add.l #1, d0
    bra .returnToLoop
    * move the bullet to the right
.moveRight
    move.w BULL_X_VEL_OFFSET(a3), d2
    add.w d2, BULL_X_POS_OFFSET(a3)
    
    * move the bullet center x
    add.w d2, BULL_CENTER_X_OFFSET(a3)
    
    * check for right wall collision
    cmp.w #RIGHT_WALL-BULL_DIMENSION, BULL_X_POS_OFFSET(a3)
    blt .bounceCheck
    * if the bullet collides, disable it and give the user a point
    move.w #0, BULL_ACTIVE_OFFSET(a3)
    add.l #1, d0
    bra .returnToLoop
    * check if the bullet bounces or not
.bounceCheck
    * if the bullet does not bounce, branch back to the loop
    tst.w BULL_TYPE_OFFSET(a3)
    beq .returnToLoop
    
    * add gravity to the bullet's y velocity
    add.w #GRAVITY, BULL_Y_VEL_OFFSET(a3)
    
    * derive ground y value in 12.4 fixed point
    move.l #0, d4
    move.w #FLOOR-BULL_DIMENSION, d4
    lsl.w #4, d4
    * check for ground collision
    move.w BULL_Y_VEL_OFFSET(a3), d2
    add.w BULL_FP_Y_POS_OFFSET(a3), d2
    
    cmp.w d4, d2
    blt .airborne
    * if on/below ground, move position to the ground
    * and negate velocity
    move.w d4, d2
    neg.w BULL_Y_VEL_OFFSET(a3)
    
.airborne
    * save the fixed point position
    move.w d2, BULL_FP_Y_POS_OFFSET(a3)
    * round the fixed point (12.4) value
    add.w #8, d2
    lsr.w #4, d2
    move.w d2, BULL_Y_POS_OFFSET(a3)
    
    * update center y position
    add.w #BULL_HALF_DIMENSION, d2
    add.w #1, d2
    move.w d2, BULL_CENTER_Y_OFFSET(a3)
    
    
    bra .returnToLoop


.done
    movem.l (sp)+, .REGS
    rts

*---
* Creates a bullet in the first available slot in the bullet list
* 
* d2 - max number of bullets
* a4 - bullet list start address
*
* out d0.b - 0 = success, non-zero = failure (list full)
*---
bull_createBullet:
.REGS  REG D2
    movem.l .REGS, -(sp)
    * find an inactive bullet
    move.l d2, d0
    move.l #BULL_SIZE, d1
    mulu d0, d1
    move.l d1, d2
    
    move.l a4, a1
    add.l a4, d2
.searchLoop
    move.w BULL_ACTIVE_OFFSET(a1), d1
    tst.w d1
    beq .inactiveFound
    add.l #BULL_SIZE, a1
    * check if end of list has been reached
    cmp.l d2, a1
    blt .searchLoop
    bra .allActive
.inactiveFound
    * set active
    move.w #1, BULL_ACTIVE_OFFSET(a1)
    * generate bullet type
    move.l #0, d0
    move.l #1, d1
    bsr bull_randNum
    move.w d0, BULL_TYPE_OFFSET(a1)
    * generate bullet start height
    move.l #CEILING, d0
    move.l #FLOOR-BULL_DIMENSION, d1
    bsr bull_randNum
    move.w d0, BULL_Y_POS_OFFSET(a1)
    lsl.w #4, d0
    move.w d0, BULL_FP_Y_POS_OFFSET(a1)
    * assign y velocity of 0
    move.w #0, BULL_Y_VEL_OFFSET(a1)
    * generate bullet speed
    move.l #BULL_MIN_SPEED, d0
    move.l #BULL_MAX_SPEED, d1
    bsr bull_randNum
    move.w d0, BULL_X_VEL_OFFSET(a1)
    * generate starting wall
    move.l #0, d0
    move.l #1, d1
    bsr bull_randNum
    tst.w d0
    beq .leftWall
    * start from the right wall
    move.w #RIGHT_WALL-BULL_DIMENSION, BULL_X_POS_OFFSET(a1)
    move.w #0, BULL_START_OFFSET(a1)
    bra .center
.leftWall
    move.w #LEFT_WALL, BULL_X_POS_OFFSET(a1)
    move.w #1, BULL_START_OFFSET(a1)

    * find the center of the bullet
.center
    move.w #BULL_HALF_DIMENSION+1, d0
    add.w BULL_X_POS_OFFSET(a1), d0
    move.w d0, BULL_CENTER_X_OFFSET(a1)
    move.w #BULL_HALF_DIMENSION+1, d0
    add.w BULL_Y_POS_OFFSET(a1), d0
    move.w d0, BULL_CENTER_Y_OFFSET(a1)
    move.b #0, d0
    bra .done
.allActive
    move.b #1, d0
.done
    movem.l (sp)+, .REGS
    rts
    

*---
* Returns a random number in the specified range
* 
* d0 - min number
* d1 - max number
*
* out d0 - random number in range
*---
bull_randNum:
.REGS  REG D2-D4
    movem.l .REGS, -(sp)
    *** Code shamelessly recycled from Jeremy's RandomNumbers.x68 file
    move.w d0, d3
    move.w d1, d4
    add.w #1, d4
    sub.w d3, d4
    
    move.l BULL_RANDOMVAL, d0
    moveq #$AF-$100, d1
    moveq #18, d2
.Ninc0	
    add.l d0, d0
    bcc .Ninc1
    eor.b d1, d0
.Ninc1
    dbf d2, .Ninc0
	
    move.l d0, BULL_RANDOMVAL

    move.b d0, d2
    divu d4, d2
    swap d2
    add.w d2, d3
    move.w d3, d0
.done
    movem.l (sp)+, .REGS
    rts


BULL_RANDOMVAL  ds.l 1
BULL_ART_ADDR   ds.l 1





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
