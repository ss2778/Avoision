*-----------------------------------------------------------
* Title      : Assembly Game (Avoision)
* Written by : Brandon Holtzman
* Date       : 10/6/24
* Description: Bullet Hell dodging game
*-----------------------------------------------------------
LEFT_WALL                      EQU      105
RIGHT_WALL                     EQU      555
FLOOR                          EQU      336
FP_FLOOR                       EQU      $1500
CEILING                        EQU      79

FRAMES_BETWEEN_BULLETS         EQU      5
MAX_BULLET_NUMBER              EQU      10
* GRAVITY is in 12.4 fixed point format
GRAVITY                        EQU      $2

CYCLES_PER_FRAME               EQU      150000
CLEAR_CYCLES                   EQU      30
GET_CYCLES                     EQU      31
GET_USER_INPUT                 EQU      19
R_KEY                          EQU      82
DRAWING_MODE                   EQU      92
WIDTH_OFFSET                   EQU      $12
HEIGHT_OFFSET                  EQU      $16
DOUBLE_BUFFERED_MODE           EQU      17
REPAINT_SCREEN                 EQU      94
OUTPUT_RESOLUTION_TRAP_CODE    EQU      33
OUTPUT_WIDTH                   EQU      640
OUTPUT_HEIGHT                  EQU      480
TASK_PRINT                     EQU      13
HEAP_SIZE                      EQU      $C00200

    ORG    $1000
    ***
    *** ALL 7SEG IMPLEMENTATION IS IN SEVSEG.X68
    ***
    INCLUDE "sevSeg.x68"
    INCLUDE "bullet.x68"
    INCLUDE "character.x68"
    INCLUDE "bitmap32.x68"
    INCLUDE "file.x68"
    INCLUDE "memory.x68"

* Register Usage:
* d2 - max number of bullets
* d3 - bullet generation counter
* a2 - background image address
* a3 - character object address
* a4 - bullet list address
START:
    * set up heap
    lea HeapStart, a1
    move.l #HEAP_SIZE, d1
    bsr mem_InitHeap
    tst.b d0
    bne .error
    
    * set the resolution of the output window
    move.b #OUTPUT_RESOLUTION_TRAP_CODE, d0
    move.l #OUTPUT_WIDTH, d1
    swap.w d1
    move.w #OUTPUT_HEIGHT, d1
    trap #15
    
    * set buffer mode
    move.l #0, d5
    move.b #DRAWING_MODE, d0
    move.b #DOUBLE_BUFFERED_MODE, d1
    trap #15
    
    * load and draw the background
    lea backFile, a1
    bsr bmp_Load
    tst.b d0
    bne .error
    
    * store the address of the background
    move.l a0, a2
    * draw the background
    move.l #0, d1
    move.l #0, d0
    move.l a2, a1
    move.w WIDTH_OFFSET(a2), d2
    swap d2
    move.w HEIGHT_OFFSET(a2), d2
    bsr bmp_Draw
    move.b #REPAINT_SCREEN, d0
    trap #15
    
    * create the bullet list
    move.l #MAX_BULLET_NUMBER, d0
    lea bullFILE, a4
    bsr bull_createBulletList
    tst.b d0
    bne .error
    move.l a0, a4
    
    * create the character
    lea charFile, a1
    bsr char_createChar
    move.l a0, a3
    
    * initialize numerical displays
    bsr sseg_init
    move.l #MAX_BULLET_NUMBER, d2
    
    * reset frame counter for bullet generation
    move.l #0, d3
    bra .gameLoop
.resetGame
    * reset character position
    bsr char_resetChar
    
    * reset numerical displays
    bsr sseg_init
    
    * clear all bullets
    bsr bull_destroy
    
    * reset frame counter for bullet generation
    move.l #0, d3
.gameloop
    * reset the cycle counter
    move.l #CLEAR_CYCLES, d0
    trap #15
    ***
    *** USER INPUT IS IN CHAR_MOVE SUBROUTINE
    ***
    *** CHAR_MOVE ALSO INCLUDES CHARACTER PHYSICS
    ***
    *** CHAR_MOVE ALSO INCLUDES COLLISION WITH THE FLOOR AND WALLS
    ***
    bsr char_Move
    ***
    *** BITMAP REQUIREMENTS IN *_DRAW AND *_ERASE SUBROUTINES
    ***
    bsr char_draw
    bsr bull_drawBullets
    move.b #REPAINT_SCREEN, d0
    trap #15
    bsr char_erase
    bsr bull_eraseBullets
    ***
    *** BULL_CHECKHIT CHECKS FOR COLLISION WITH THE CHARACTER
    ***
    bsr bull_checkHit
    * check for loss
    tst.b d0
    bne .loss
    ***
    *** BULL_MOVE CHECKS FOR COLLISION WITH THE WALLS
    ***
    ***
    *** BULL_MOVE IMPLEMENTS PHYSICS AND FLOOR COLLISION FOR THE BOUNCING BULLETS
    ***
    bsr bull_move
    ***
    *** SSEG_DRAWSCORE IMPLEMENTS A MULTI-DIGIT SEVEN SEGMENT DISPLAY (7SEG)
    ***
    bsr sseg_drawScore
    cmp.l #FRAMES_BETWEEN_BULLETS, d3
    blt .noNewBullet
    move.l #0, d3
    ***
    *** BULL_CREATEBULLET IMPLEMENTS RANDOM GENERATION IN SEVERAL INSTANCES
    ***
    * generate new bullet
    bsr bull_createBullet
    ***
    *** BULL_CREATEBULLET IMPLEMENTS RANDOM GENERATION IN SEVERAL INSTANCES
    ***
.noNewBullet
    add.l #1, d3
* stall for target fps
.fpsStallLoop
    move.l #GET_CYCLES, d0
    trap #15
    cmp.l #CYCLES_PER_FRAME, d1
    blt .fpsStallLoop
    bra .gameloop
    
.loss
    * update to show last life lost
    move.b #REPAINT_SCREEN, d0
    trap #15
.lossLoop
    * check if the R key was pressed
    move.l #R_KEY, d1
    move.b #GET_USER_INPUT, d0
    trap #15
    * if the R key was pressed, reset the game
    * otherwise, continue to check for the input
    andi.l #$000000FF, d1
    beq .lossLoop
    bra .resetGame
    
.error
    moveq   #TASK_PRINT, d0
    lea     ErrorLabel, a1
    trap    #15
.done
    SIMHALT             ; halt simulator

* Put variables and constants here
ErrorLabel      dc.b    'An error was encountered',0
charFile        dc.b    'character.bmp',0
bullFile        dc.b    'bullet.bmp',0
backFile        dc.b    'background.bmp',0
    ds.w 0
HeapStart
    END    START        ; last line of source















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
