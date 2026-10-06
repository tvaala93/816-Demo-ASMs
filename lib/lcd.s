; ============================================================
; lcd.s
;
; Driver for a 16x2 HD44780-compatible character LCD wired to
; the W65C22 VIA in 4-bit mode:
;
;   PB0 -> LCD RS
;   PB1 -> LCD R/W
;   PB2 -> LCD E
;   PB3 -> LCD DB4
;   PB4 -> LCD DB5
;   PB5 -> LCD DB6
;   PB6 -> LCD DB7
;   PB7 -> No Connect
;
; Public interface (the only labels other files should call):
;   lcdInit      - resynchronize the LCD and enter 4-bit mode
;   lcdCfgCmd    - send a configuration byte (RS=0)
;   lcdWriteChar - send a character byte     (RS=1)
;
; toggleE and lcdWait are private implementation details used
; only within this file, and are deliberately NOT exported --
; nothing outside lcd.s should be reaching into them.
; ============================================================

    .setcpu "65816"
    .a8
    .i8
    .smart

    .include "inc/thru_defs.inc"
    .export lcdSetup, lcdCfgCmd, lcdWriteChar, lcdCursU, lcdCursD, lcdCursL, lcdCursR, lcdNewline

    .segment "CODE"

TEMP = $10

lcdSetup:
    jsr viaInit    
    stz CURS_POSN
    stz LCD_OFFSET
    ldx #60
@outer:
    ldy #0
@inner:
    dey                     ; 2
    bne @inner              ; 3  -> ~1280 cycles per outer pass
    dex
    bne @outer              ; 60 passes ~ 77k cycles ~ 42 ms @ 1.8432 MHz
    jsr lcdInit
    lda #%00101000          ; 4-bit mode; 2 lines; 5x8 font
    jsr lcdCfgCmd
    lda #%00001110          ; display on, cursor on, blink off
    jsr lcdCfgCmd
    lda #%00000110          ; increment, no shift
    jsr lcdCfgCmd
    lda #LCD_CLEAR          ; clear display
    jsr lcdCfgCmd
    rts

viaInit:  
  lda #%11111111
  sta DDRB  
  rts

; -------------------------------------
; The LCD may have been left halfway through a byte by a warm
; reset.  Send the 8-bit-mode wake-up nibble three times so the
; controller is synchronized before selecting 4-bit mode.
; -------------------------------------
lcdInit:    
    lda #%00011000 ; LCD nibble 0011 (DB4..DB7 on PB3..PB6)
    jsr lcdInitNibble
    jsr lcdInitDelay
    jsr lcdInitNibble
    jsr lcdInitDelay
    jsr lcdInitNibble
    jsr lcdInitDelay
    lda #%00010000 ; LCD nibble 0010: select 4-bit mode
    jsr lcdInitNibble
    rts

lcdInitNibble:
    sta PORTB
    ora #E
    sta PORTB
    and #%01111000
    sta PORTB
    rts

lcdInitDelay:
    ldy #$ff
lcdInitDelayLoop:
    ldx #$ff
lcdInitDelayInnerLoop:
    dex
    bne lcdInitDelayInnerLoop
    dey
    bne lcdInitDelayLoop
    rts

toggleE:
    ora #E            ; Set E bit to send instruction
    sta PORTB
    eor #E            ; Clear E bit
    sta PORTB
    rts

; -------------------------------------
; Poll LCD busy flag instead of using
; a fixed delay
; to check Busy flag need to set 
; RS = 0, RW = 1
; -------------------------------------
lcdWait:
    pha
    lda #%10000111    ; LCD data is input
    sta DDRB
lcdBusy:
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB         ; Read high nibble
    pha               ; and put on stack since it has the busy flag
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB         ; Read low nibble
    pla               ; Get high nibble off stack
    and #%01000000    ; Read DB7 for busy flag
    bne lcdBusy

    lda #RW
    sta PORTB
    lda #%11111111    ; Cfg PORTB to be output again
    sta DDRB
    pla
    rts

; -------------------------------------
; Send an instruction to the LCD
; -------------------------------------
lcdCfgCmd:          ; Send a configuration command to LCD
    jsr lcdWait
    pha
    lsr               ; Shift high 4 bits to correct pins
    and #%01111000    ; Mask off other bits
    sta PORTB
    jsr toggleE
    pla
    asl
    asl
    asl               ; Shift low 4 bits to fit in PB3-6
    and #%01111000    ; Mask off other bits
    sta PORTB
    jsr toggleE
    rts

; -------------------------------------
; Send a character to the LCD
; -------------------------------------
lcdWriteChar:
    jsr lcdWait
    pha
    lsr               ; Shift 4 high bits
    and #%01111000    ; Mask off other bits
    ora #RS           ; Set RS bit
    sta PORTB
    jsr toggleE
    pla
    asl
    asl
    asl               ; Shift low 4 bits to fit in PB3-6
    and #%01111000    ; Mask off other bits
    ora #RS
    sta PORTB
    jsr toggleE
    
    ; Bookkeeping to update DDRAM and offset
    lda CURS_POSN       ; Get tracked DDRAM address
    inc
    cmp #80
    bcc @store
    lda #79
@store:
    sta CURS_POSN
    jmp lcdSyncViewport
    

; -------------------------------------
; Cursor Directional Handlers
; -------------------------------------
lcdCursU:
    lda CURS_POSN
    cmp #$28
    bcc @done
    sec
    sbc #$28        ; Else move cursor up by subtracting 40
    sta CURS_POSN
    jsr lcdSyncViewport
@done:   
    rts

lcdCursD:
    lda CURS_POSN
    cmp #$28
    bcc @move_down
    ; already on row 2, so don't move further
    jmp @done
@move_down:
    lda CURS_POSN
    clc
    adc #$28
    cmp #$50
    bcs @done
    sta CURS_POSN
    jsr lcdSyncViewport
@done:   
    rts

; Move cursor left
; If cursor is in left-most cell, 
; check for add'l characters and shift entire display
lcdCursL:
    lda CURS_POSN
    beq @done          ; We're at left-most column of top row
    dec
    sta CURS_POSN
    jsr lcdSyncViewport
@done:   
    rts

; Move cursor right
; If cursor is in right-most cell, 
; check for add'l characters and shift entire display
lcdCursR:
    lda CURS_POSN
    cmp #79
    beq @done          ; We're at right-most column of bottom row
    inc
    sta CURS_POSN
    jsr lcdSyncViewport
@done:   
    rts


; -------------------------------------
; Enter: go to column 0 of the next row
; (from the bottom row, wrap to the top row)
; -------------------------------------
lcdNewline:
    lda CURS_POSN
    cmp #$28            ; carry set if already on row 2
    lda #$28            ; (lda doesn't touch carry) default: start of row 2
    bcc @set
    lda #0              ; was on row 2: wrap to start of row 1
@set:
    sta CURS_POSN
    jmp lcdSyncViewport


; -------------------------------------
; Send the real LCD cursor to CURS_POSN.
; CURS_POSN is a 0-79 logical index (row 2 = 40-79) but the HD44780's
; DDRAM row 2 starts at $40, not $28:  addr = pos (row 1), pos+$18 (row 2)
; -------------------------------------
lcdSetCursor:
    lda CURS_POSN
    cmp #$28
    bcc @send
    clc
    adc #$18
@send:
    ora #$80            ; "Set DDRAM address" command
    jmp lcdCfgCmd       ; tail call


; -------------------------------------
; Scroll the 16-column window until the cursor column is inside it,
; then put the hardware cursor on the cursor cell.
; -------------------------------------
lcdSyncViewport:    
    lda CURS_POSN
    cmp #$28                
    bcc @col_ok    
    sbc #$28                ; If >= 40, subtract 40
@col_ok:
    sta TEMP
@left:                  ; Cursor left of window?
    lda TEMP
    cmp LCD_OFFSET
    bcs @right    ; col >= offset
    dec LCD_OFFSET
    lda #LCD_SHIFTR     ; window moves left over data
    jsr lcdCfgCmd
    bra @left
@right:                 ; Cursor right of window?
    lda LCD_OFFSET
    clc
    adc #(LCDCOLS - 1)  ; Right-most visible column
    cmp TEMP
    bcs @place          ; Right edge >= col
    inc LCD_OFFSET
    lda #LCD_SHIFTL
    jsr lcdCfgCmd
    bra @right
@place:
    jmp lcdSetCursor