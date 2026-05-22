.include "header.inc"
.include "InitSNES.asm"
.include "macros.inc"

;-------
.BANK 0 SLOT 0
.ORG 0
.SECTION "VBlank"
VBlank:
@WaitForJoypadStart:
    lda $4212      
    and #$00000001 
    beq @WaitForJoypadStart ; Loops until bit 0 turns ON (1)

    ; --- 2. WAIT FOR JOYPAD TO FINISH READING ---
@WaitForJoypadFinish:
    lda $4212      
    and #$00000001 
    bne @WaitForJoypadFinish ; Loops until bit 0 turns OFF (0)

    lda $4219      ;read joypad #1
    sta $0201      ;store it (high byte)
    lda $4218      ;read joypad #2
    sta $0202      ;store it (low byte)

    AXY8           ; Make sure Accumulator is 8-bit
    lda $0203      ; Load PREVIOUS frame's high byte
    eor #$FF       ; EOR with $FF flips all the bits (This gives us NOT Previous)
    and $0201      ; AND it with the CURRENT frame's high byte
    sta $0205      ; Store the result! This is now your NEWLY PRESSED High Byte.

    ;a/b/x/y/l/r/e/t = A/B/X/Y/L/R/Select/Start button status.
    ;high = byetUDLR | low = axlr0000

    
    ;and #$00100000 ;Select Button
    ;Clear the screen

    ;and #$00010000 ;Start Button
    ;Pause/Play Toggle of Simulation

    ;and #$01000000 ;Y pressed

    ;and #$10000000 ;B Pressed

    lda $0202 ;check if A is pressed
    and #%10000000
    bne @SetAlive ;if pressed, set alive

    lda $0201 ;check if B is pressed
    and #%10000000
    bne @SetDead;


    jmp @SkipDraw ;neither A or B pressed, skip updating dead cells;
@SetAlive
    AXY16
    lda #$0001     ; Load Tile 1 (Alive)
    jmp @WriteTile ; Jump to writing phase

@SetDead
    AXY16   ; Switch to 16-bit A
    lda #$0003    ; Load Tile 3 (Dead)
    jmp @WriteTile ; Jump to writing phase  

@WriteTile
    sta $0208      ;Store tile to write
    ; --- CALCULATE VRAM ADDRESS ---
    ; Address = Base ($4000) + (Scroll Y * 32) + Scroll X
    lda $0101      ;Load scroll Y
    and #$00FF     ;Ensure it's within 0-255
    asl a
    asl a
    asl a
    asl a
    asl a
    sta $020A      ;Store Y offset    

    lda $0100      ;Load scroll X
    and #$00FF     ;Ensure it's within 0-255
    clc
    adc $020A      ; Add Y offset to X
    clc
    adc #$4000     ; Add Background VRAM Base Address ($4000)
    tax

    A8
    ;lda #$80
    ;sta $2115      ;Set VRAM transfer mode to word-access, increment by 1

    stx $2116      ;Set VRAM Address for writing
    A8
    lda $0208      ;Load tile to write
    sta $2118      ;Write tile to VRAM

    AXY8

    jmp @SkipDraw

@SkipDraw
    AXY8           ; Ensure Accumulator is 8-bit

    ; 1. Check if ANY D-Pad button is currently held
    lda $0201      ; Current held buttons
    and #%00001111 ; Mask out everything except U, D, L, R
    beq @ResetDAS  ; If equal to zero (nothing held), reset the timer!

    ; 2. Check if it is a BRAND NEW press
    lda $0205      ; Newly pressed buttons (from your edge detection)
    and #%00001111 
    bne @InitialPress ; If a new D-Pad button was pressed, jump to initial setup

    ; 3. Button is being HELD. Handle the Timer.
    dec $0206      ; Subtract 1 from the DAS Timer
    bne @SkipCursor; If the timer hasn't hit 0 yet, skip movement

    ; 4. Timer hit 0! Trigger the auto-repeat slide.
    lda #$04       ; SLIDE SPEED: Wait 4 frames between fast movements
    sta $0206      ; Reset timer to short delay
    lda $0201      ; Load the HELD buttons into Accumulator
    and #%00001111
    sta $0207
    bra @MoveCursor


@InitialPress:
    lda #$14       ; INITIAL DELAY: Wait 20 frames (~1/3 second) before sliding
    sta $0206      ; Set timer to long delay
    lda $0205      ; Load the NEWLY PRESSED buttons into Accumulator
    and #%00001111 
    sta $0207
    bra @MoveCursor

@ResetDAS:
    stz $0206      ; Store Zero to the DAS Timer (resets it)
@SkipCursor:
    bra @DoneCursor; Jump past the movement logic entirely

@MoveCursor:
    ;Cursor Logic (UDLR)
    lda $0207      ;get control
    and #%00001111 ;care abt direction
    ;sta $0201      ;store dirs

    cmp #%00001000 ;up?
    bne +          ;skip if no
    lda $0101      ;get scroll Y
    cmp #$00       ;if on the top,
    beq +          ;don't do anything
    dec $0101      ;sub 1 from Y
    +

    lda $0207      ;get control
    and #%00001111 ;care abt direction
    cmp #%00000100 ;down?
    bne +          ;skip if no
    lda $0101      ;get scroll Y
    cmp #$1F       ;if on the bottom,
    beq +          ;don't do anything
    inc $0101      ;sub 1 from Y
    +

    lda $0207      ;get control
    and #%00001111 ;care abt direction
    cmp #%00000010 ;left?
    bne +          ;skip if no
    lda $0100      ;get scroll X
    cmp #$00       ;if on the left,
    beq +          ;don't do anything
    dec $0100      ;sub 1 from X
    +

    lda $0207      ;get control
    and #%00001111 ;care abt direction
    cmp #%00000001 ;right?
    bne +          ;skip if no
    lda $0100      ;get scroll X
    cmp #$1F       ;if on the right,
    beq +          ;don't do anything
    inc $0100      ;sub 1 from X
    +

    stz $2102 ;OAM ADDRESS Low
    stz $2103 ;OAM ADDRESS High

    lda $0100 ;Load scroll X
    asl a     ; x2
    asl a     ; x4
    asl a     ; x8 (tile size)
    sta $2104 ;OAM Data

    lda $0101 ;Load scroll Y
    asl a     ; x2
    asl a     ; x4
    asl a     ; x8 (tile size)
    sta $2104 ;OAM Data

    lda #$00  ;First Sprite Name (Sprite 0)
    sta $2104 ;OAM Data
    lda #%00110000  ;No flip, prio, and pal 0
    sta $2104 ;OAM Data

@DoneCursor:
    lda $0205      ; Load NEWLY PRESSED High Byte (Edge Detected!)
    and #%00010000 ; Check Bit 4 (Start Button)
    beq +; If not pressed, skip the toggle

    ; Toggle the Simulation Flag
    lda $0210      ; Load current flag state
    eor #$01       ; Exclusive OR with 01 flips it! (00 becomes 01, 01 becomes 00)
    sta $0210      ; Store it back
    +

    ;Cleanup
    lda $0201       
    sta $0203       ; Save Current High Byte to Previous High Byte

    rti ;finish...
.ENDS

;--------
.BANK 0 SLOT 0
.ORG 0
.SECTION "Main"
Start:
    InitSNES

    XY16
    A8

    ;setup sprite config
    lda #%00000011  ; Size: 8x8/16x16, Base: $6000
    sta $2101

    ;Load background pallete that will be used
    stz $2121
    ldx #$0000
    - lda CellsTilePal.l, x ;Load pallete
    sta $2122
    inx
    cpx #$32 ;Len of pallete data
    bne -

    ;Load Sprite Palette (CURSOR)
    ;Slot 8 -> Index 128 

    lda #$80        ;Set CGRAM Addr to sprite area
    sta $2121
    ldx #$0000

    - lda CursorTilePal.l, x ;Load pallete
    sta $2122
    inx
    cpx #$32 ;Len of pallete data
    bne -

    ;load Cursor.chr DMA Transfer
    ldx #CursorTile         ; Your sprite graphics label
    stx $4302               ; Source Low/High
    lda #:CursorTile        ; Source Bank
    sta $4304
    
    ldy #128                ; Size (e.g., 4 tiles * 32 bytes)
    sty $4305
    
    lda #$01                ; Word Transfer
    sta $4300
    lda #$18                ; Dest: VRAM Data ($2118)
    sta $4301

    ; Set VRAM Dest to $6000 (Word Address $3000)
    ldx #$6000
    stx $2116

    lda #$01                ; Fire DMA Channel 0
    sta $420B
    
    stz $2102 ;OAM ADDRESS Low
    stz $2103 ;OAM ADDRESS High

    lda #(256/2 - 8)
    sta $2104 ;OAM Data
    lda #(224/2 - 8)
    sta $2104
    lda #$00  ;First Sprite Name (Sprite 0)
    sta $2104
    lda #%00110000  ;No flip, prio, and pal 0
    sta $2104


    ;DMA Trasfer for Backgrounding
    ldx #CellsTile
    lda #:CellsTile
    ldy #(CellsTilePal-CellsTile)
    stx $4302
    sta $4304
    sty $4305
    lda #%00000001     ;set the mode (word transfer)
    sta $4300
    lda #$18           ;VRAM data write $211[89]
    sta $4301          ;set dest

    ldx #$0000         ;write VRAM from $0000
    stx $2116

    lda #%00000001     ;Fire DMA Channel 0
    sta $420B

    AXY16

    ;Start drawing our initial board
    ;Checkerboard for now...
    lda #%10000000 ;VRAM Writing mode
    sta $2115
    ldx #$4000     ;write to VRAM
    stx $2116      ;from $4000
    ;32x32 grid :)

    lda #$0001 ;Tile Index 1 (Alive)
    ldy #32    ;32 Rows

@RowLoop:
    ldx #32    ;32 Cols
@ColLoop:
    sta $2118  ;Write Tile to VRAM
    eor #$0011 ;Toggle between 1 and 2
    dex        ;dec col counter
    bne @ColLoop

    eor #$0011 ;Toggle once again to offset checkerboard
    dey        ;dec row counter
    bne @RowLoop

    A8

    lda #%00000001  ;16x16 tiles, mode 0
    sta $2105       ;screen mode register
    lda #%01000000  ;data starts at $4000
    sta $2107       ;BG1

    stz $210B

    lda #%00010001  ;enable BG1 + Objs
    sta $212C

    lda #%00001111  ;enable screen, set bright to 15
    sta $2100

    lda #%10000001  ;enable NMI and joypads
    sta $4200

loop:
    lda $0210      ; Check Simulation Flag
    beq @RunCursorMode

    ; If running, JUMP to our new subroutine!
    jsr RunSimulation 
    bra @EndFrame

@RunCursorMode:
    ; Cursor movement and stuff?
    bra @EndFrame

@EndFrame
    wai ;Wait for interrupt
    jmp loop

.include "Sim.asm"
.ENDS

;-------
.BANK 1 SLOT 0
.ORG 0
.SECTION "GraphicsData"
    ;Cells (Dead, Alive, Emplty?)
    CellsTile:
        .incbin "Imgs/GOLTiles.chr"
    CellsTilePal:
        .incbin "Imgs/GOLTiles.pal"

    ;Cursor
    CursorTile:
        .incbin "Imgs/GOLCursor.chr"
    CursorTilePal:
        .incbin "Imgs/GOLCursor.pal"
.ENDS

