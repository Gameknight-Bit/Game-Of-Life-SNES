.include "header.inc"
.include "InitSNES.asm"
.include "macros.inc"

;-------
.BANK 0 SLOT 0
.ORG 0
.SECTION "VBlank"
VBlank:
    lda $4212      ;get joypad status
    and #$00000001 ;if joy not ready
    bne VBlank     ;branch back if not
    lda $4219      ;read joypad #1
    sta $0201      ;store it
    cmp $0200      ;Check if equal to prev
    bne +
    rti            ;if equal return

    ;a/b/x/y/l/r/e/t = A/B/X/Y/L/R/Select/Start button status.
    ;high = byetUDLR | low = axlr0000
    + sta $0200    

    
    ;and #$00100000 ;Select Button
    ;Clear the screen

    ;and #$00010000 ;Start Button
    ;Pause/Play Toggle of Simulation

    ;and #$01000000 ;Y pressed

    ;and #$10000000 ;B Pressed


    ;Cursor Logic
    lda $0201      ;get control
    and #%00001111 ;care abt direction
    sta $0201      ;store dirs

    cmp #%00001000 ;up?
    bne +          ;skip if no
    lda $0101      ;get scroll Y
    cmp #$00       ;if on the top,
    beq +          ;don't do anything
    dec $0101      ;sub 1 from Y
    +

    lda $0201      ;get control
    cmp #%00000100 ;down?
    bne +          ;skip if no
    lda $0101      ;get scroll Y
    cmp #$02       ;if on the bottom,
    beq +          ;don't do anything
    inc $0101      ;sub 1 from Y
    +

    lda $0201      ;get control
    cmp #%00000010 ;left?
    bne +          ;skip if no
    lda $0100      ;get scroll X
    cmp #$00       ;if on the left,
    beq +          ;don't do anything
    dec $0100      ;sub 1 from X
    +

    lda $0201      ;get control
    cmp #%00000001 ;right?
    bne +          ;skip if no
    lda $0100      ;get scroll X
    cmp #$02       ;if on the right,
    beq +          ;don't do anything
    inc $0100      ;sub 1 from X
    +

    lda $0201      ;get control

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
    ldx #$3000
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
    lda #%00100000  ;No flip, prio, and pal 0
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
    wai ;Wait for interrupt
    jmp loop
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

