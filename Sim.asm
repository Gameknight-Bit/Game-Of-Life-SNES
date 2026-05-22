RunSimulation:
    AXY8
    
    stz $0214 ;start row 0

@RowLoop:
    stz $0215 ;start col 0

@ColLoop:
    stz $0212      ;Clear Neightboar count for cell
    
    ;--------- START WITH COUNTING NEIGHBORS!!!!! ----------
    ; --- Check TOP-LEFT Neighbor ---
    lda $0214      ; Load Current Row
    dec a          ; Row - 1 (Up)
    and #$1F       ; Wrap-around
    sta $0216      ; Store to Target Row

    lda $0215      ; Load Current Column
    dec a          ; Column - 1 (Left)
    and #$1F       ; Wrap-around
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check TOP Neighbor ---
    lda $0214      ; Load Current Row
    dec a          ; Row - 1 (Up)
    and #$1F       ; Wrap-around
    sta $0216      ; Store to Target Row

    lda $0215      ; Load Current Column
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check TOP-RIGHT Neighbor ---
    lda $0214      ; Load Current Row
    dec a          ; Row - 1 (Up)
    and #$1F       ; Wrap-around
    sta $0216      ; Store to Target Row
    
    lda $0215      ; Load Current Column
    inc a          ; Column + 1 (Right)
    and #$1F       ; Wrap-around
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check LEFT Neighbor ---
    lda $0214      ; Load Current Row
    sta $0216      ; Store to Target Row
    
    lda $0215      ; Load Current Column
    dec a          ; Column - 1 (Left)
    and #$1F       ; Wrap-around
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check RIGHT Neighbor ---
    lda $0214      ; Load Current Row
    sta $0216      ; Store to Target Row
    
    lda $0215      ; Load Current Column
    inc a          ; Column + 1 (Right)
    and #$1F       ; Wrap-around
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check BOTTOM-LEFT Neighbor ---
    lda $0214      ; Load Current Row
    inc a          ; Row + 1 (Down)
    and #$1F       ; Wrap-around
    sta $0216      ; Store to Target Row
    
    lda $0215      ; Load Current Column
    dec a          ; Column - 1 (Left)
    and #$1F       ; Wrap-around
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check BOTTOM Neighbor ---
    lda $0214      ; Load Current Row
    inc a          ; Row + 1 (Down)
    and #$1F       ; Wrap-around
    sta $0216      ; Store to Target Row
    
    lda $0215      ; Load Current Column
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back

    ; --- Check BOTTOM-RIGHT Neighbor ---
    lda $0214      ; Load Current Row
    inc a          ; Row + 1 (Down)
    and #$1F       ; Wrap-around
    sta $0216      ; Store to Target Row
    
    lda $0215      ; Load Current Column
    inc a          ; Column + 1 (Right)
    and #$1F       ; Wrap-around
    sta $0217      ; Store to Target Column

    jsr GetNeighborState ; A now holds 00 or 01!
    clc
    adc $0212      ; Add A to our Neighbor Counter
    sta $0212      ; Store it back
    ;--------- DONE WITH COUNTING NEIGHBORS!!!!! ----------


    ; -------------------------------------------------------------
    ; [2] APPLY CONWAY'S RULES
    ; -------------------------------------------------------------
    
    ; Get X-offset for current cell
    lda $0214      ; Current Row
    sta $0216
    lda $0215      ; Current Column
    sta $0217
    jsr GetNeighborState ; We don't care about the Accumulator here, 
                         ; but X now perfectly holds our 1D offset!

    ; Now apply the optimized rules
    lda $0212      ; Load the total neighbor count
    cmp #$03       ; Is it exactly 3?
    beq @SetAlive  

    cmp #$02       ; Is it exactly 2?
    beq @KeepState 

@SetDead:
    lda #$00       ; Otherwise, it dies (or stays dead)
    bra @WriteNext

@SetAlive:
    lda #$01       ; It lives (or is born)
    bra @WriteNext

@KeepState:
    lda $0400, x   ; Read the CURRENT state from the Current Board
    bra @WriteNext

@WriteNext:
    ; -------------------------------------------------------------
    ; [3] WRITE TO NEXT BOARD
    ; -------------------------------------------------------------
    sta $0800, x   ; Save the new state to the Next Board!

    inc $0215      ;inc col counter  
    lda $0215
    cmp #$20       ;are we at col 32?
    beq @ColLoopDone ;Inversion to allow for 16-bit reference jumps
    jmp @ColLoop     
@ColLoopDone:

    inc $0214      ;inc row counter
    lda $0214
    cmp #$20       ;are we at row 32?
    beq @RowLoopDone 
    jmp @RowLoop     
@RowLoopDone:

    ; -------------------------------------------------------------
    ; [4] BUFFER SWAP (Optimized 16-bit Manual Loop)
    ; -------------------------------------------------------------
    AXY16

    ldx #$0000     ; Set our index to 0

@BufferCopyLoop:
    lda $0800, x   ; Copy TWO bytes at once into the 16-bit Accumulator
    sta $0400, x   ; Blast BOTH bytes into the Current Board

    inx            ; Increment index by 2 (X = X + 2)
    inx            
    cpx #$0400     ; Have we reached 1024 bytes? (Hex $0400)
    bne @BufferCopyLoop ; If not, loop back!

    A8
    
    rts            ; Return back to the loop...


GetNeighborState:
    ; In: $0216 - Target Row, $0217 - Target Column
    ; Out: A = 00 or 01 depending on if the cell is alive or dead

    A16
    
    lda $0216      ; Load Target Row
    and #$001F     ; Mask it to ensure we don't have garbage in the high byte
    asl a          
    asl a          
    asl a          
    asl a          
    asl a          
    sta $0218      ; Store the temp result

    ; 2. Add the Column
    lda $0217      ; Load Target Column
    and #$001F     ; Mask it
    clc            
    adc $0218      ; A now equals (Row * 32) + Column!
    
    tax            ; Transfer our finished offset into the X register

    ; 3. Read the Board
    A8
    lda $0400, x   ; Load the cell from the Current Board using our X offset!
    
    rts