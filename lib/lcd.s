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
;   lcdSetup      - init the VIA and the LCD, clear the screen
;   lcdClear      - clear the screen and home the cursor
;   lcdCfgCmd     - send a configuration byte (RS=0)
;   lcdWriteChar  - send a character byte     (RS=1), advance the cursor
;   lcdNewline, lcdCursU/D/L/R - move the cursor
; (documented in lcd.inc, which is all a caller needs to include)
;
; Everything else (lcdInit, toggleE, lcdWait, the viewport code and the
; cursor variables below) is private and deliberately NOT exported --
; nothing outside lcd.s should be reaching into it.
; ============================================================

    .setcpu "65816"
    .a8
    .i8
    .smart

    .include "thru_defs.inc"
LCD_IMPL = 1            ; this file defines the routines lcd.inc imports
    .include "lcd.inc"
    .export lcdSetup, lcdClear, lcdCfgCmd, lcdWriteChar
    .export lcdCursU, lcdCursD, lcdCursL, lcdCursR, lcdNewline

; Variables: the linker assigns the addresses (see ZEROPAGE and BSS in rom.cfg)
    .segment "ZEROPAGE" : zeropage
lcdTemp:    .res 1      ; scratch for lcdSyncViewport

    .segment "BSS"
lcdCursPosn: .res 1     ; Tracks absolute posn in 40x2 logical buff (0-79)
lcdOffset:  .res 1      ; Tracks left edge of the view port/window (0-24)
; the window shows offset through offset+15,
; and 24 is the furthest right it can go while still showing real data

    .segment "CODE"

lcdSetup:
    jsr viaInit
    ldx #60
@outer:
    ldy #0
@inner:
    dey                 ; 2
    bne @inner          ; 3  -> ~1280 cycles per outer pass
    dex
    bne @outer          ; 60 passes ~ 77k cycles ~ 42 ms @ 1.8432 MHz
    jsr lcdInit
    lda #%00101000      ; 4-bit mode; 2 lines; 5x8 font
    jsr lcdCfgCmd
    lda #%00001110      ; display on, cursor on, blink off
    jsr lcdCfgCmd
    lda #%00000110      ; increment, no shift
    jsr lcdCfgCmd
    jmp lcdClear

; -------------------------------------
; Clear the display and home the cursor. Clear also un-shifts the display,
; so the window offset goes back to 0 with it.
; -------------------------------------
lcdClear:
    stz lcdCursPosn
    stz lcdOffset
    lda #LCD_CLEAR
    jmp lcdCfgCmd       ; tail call

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
    lda #%00011000      ; LCD nibble 0011 (DB4..DB7 on PB3..PB6)
    jsr lcdInitNibble
    jsr lcdInitDelay
    jsr lcdInitNibble
    jsr lcdInitDelay
    jsr lcdInitNibble
    jsr lcdInitDelay
    lda #%00010000      ; LCD nibble 0010: select 4-bit mode
    jmp lcdInitNibble

lcdInitNibble:
    sta PORTB
    ora #E
    sta PORTB
    and #%01111000
    sta PORTB
    rts

lcdInitDelay:
    ldy #$FF
lcdInitDelayLoop:
    ldx #$FF
lcdInitDelayInnerLoop:
    dex
    bne lcdInitDelayInnerLoop
    dey
    bne lcdInitDelayLoop
    rts

toggleE:
    ora #E              ; Set E bit to send instruction
    sta PORTB
    eor #E              ; Clear E bit
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
    lda #%10000111      ; LCD data is input
    sta DDRB
lcdBusy:
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB           ; Read high nibble
    pha                 ; and put on stack since it has the busy flag
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB           ; Read low nibble
    pla                 ; Get high nibble off stack
    and #%01000000      ; Read DB7 for busy flag
    bne lcdBusy

    lda #RW
    sta PORTB
    lda #%11111111      ; Cfg PORTB to be output again
    sta DDRB
    pla
    rts

; -------------------------------------
; Send an instruction to the LCD
; -------------------------------------
lcdCfgCmd:              ; Send a configuration command to LCD
    jsr lcdWait
    pha
    lsr                 ; Shift high 4 bits to correct pins
    and #%01111000      ; Mask off other bits
    sta PORTB
    jsr toggleE
    pla
    asl
    asl
    asl                 ; Shift low 4 bits to fit in PB3-6
    and #%01111000      ; Mask off other bits
    sta PORTB
    jmp toggleE

; -------------------------------------
; Send a character to the LCD
; -------------------------------------
lcdWriteChar:
    jsr lcdWait
    pha
    lsr                 ; Shift 4 high bits
    and #%01111000      ; Mask off other bits
    ora #RS             ; Set RS bit
    sta PORTB
    jsr toggleE
    pla
    asl
    asl
    asl                 ; Shift low 4 bits to fit in PB3-6
    and #%01111000      ; Mask off other bits
    ora #RS
    sta PORTB
    jsr toggleE

    ; Bookkeeping to update DDRAM and offset
    lda lcdCursPosn     ; Advance logical position (0-79), stop at the last cell
    inc
    cmp #80
    bcc @store
    lda #79
@store:
    sta lcdCursPosn
    jmp lcdSyncViewport


; -------------------------------------
; Cursor Directional Handlers
; -------------------------------------
lcdCursU:
    lda lcdCursPosn
    cmp #$28
    bcc @done
    sec
    sbc #$28            ; Else move cursor up by subtracting 40
    sta lcdCursPosn
    jsr lcdSyncViewport
@done:
    rts

lcdCursD:
    lda lcdCursPosn
    cmp #$28
    bcc @move_down
    ; already on row 2, so don't move further
    jmp @done
@move_down:
    lda lcdCursPosn
    clc
    adc #$28
    cmp #$50
    bcs @done
    sta lcdCursPosn
    jsr lcdSyncViewport
@done:
    rts

; Move cursor left
; If cursor is in left-most cell,
; check for add'l characters and shift entire display
lcdCursL:
    lda lcdCursPosn
    beq @done           ; We're at left-most column of top row
    dec
    sta lcdCursPosn
    jsr lcdSyncViewport
@done:
    rts

; Move cursor right
; If cursor is in right-most cell,
; check for add'l characters and shift entire display
lcdCursR:
    lda lcdCursPosn
    cmp #79
    beq @done           ; We're at right-most column of bottom row
    inc
    sta lcdCursPosn
    jsr lcdSyncViewport
@done:
    rts


; -------------------------------------
; Enter: go to column 0 of the next row
; (from the bottom row, wrap to the top row)
; -------------------------------------
lcdNewline:
    lda lcdCursPosn
    cmp #$28            ; carry set if already on row 2
    lda #$28            ; (lda doesn't touch carry) default: start of row 2
    bcc @set
    lda #0              ; was on row 2: wrap to start of row 1
@set:
    sta lcdCursPosn
    jmp lcdSyncViewport


; -------------------------------------
; Send the real LCD cursor to lcdCursPosn.
; lcdCursPosn is a 0-79 logical index (row 2 = 40-79) but the HD44780's
; DDRAM row 2 starts at $40, not $28:  addr = pos (row 1), pos+$18 (row 2)
; -------------------------------------
lcdSetCursor:
    lda lcdCursPosn
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
    lda lcdCursPosn
    cmp #$28
    bcc @col_ok
    sbc #$28            ; If >= 40, subtract 40
@col_ok:
    sta lcdTemp
@left:                  ; Cursor left of window?
    lda lcdTemp
    cmp lcdOffset
    bcs @right          ; col >= offset
    dec lcdOffset
    lda #LCD_SHIFTR     ; window moves left over data
    jsr lcdCfgCmd
    bra @left
@right:                 ; Cursor right of window?
    lda lcdOffset
    clc
    adc #(LCDCOLS - 1)  ; Right-most visible column
    cmp lcdTemp
    bcs @place          ; Right edge >= col
    inc lcdOffset
    lda #LCD_SHIFTL
    jsr lcdCfgCmd
    bra @right
@place:
    jmp lcdSetCursor