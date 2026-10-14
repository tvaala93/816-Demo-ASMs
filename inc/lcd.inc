; =============================================================================
; lcd.inc -- public interface of the 16x2 LCD driver (lcd.s)
;
; Include this in any file that uses the LCD; the routines are imported for you.
;
;   lcdSetup      - init VIA port B and the LCD, clear the screen
;   lcdClear      - clear the screen and home the cursor
;   lcdWriteChar  - A = character: write it at the cursor, advance the cursor
;   lcdNewline    - cursor to column 0 of the next row (bottom row wraps to top)
;   lcdCursU/D/L/R - move the cursor one cell, scrolling the 16-column window
;   lcdCfgCmd     - A = raw HD44780 command (see LCD_* below)
;
; All of them clobber A, X and Y. The driver keeps its cursor state in its own
; private variables; use the routines above rather than reaching into them.
; =============================================================================
.ifndef LCD_INC
LCD_INC = 1

.ifndef LCD_IMPL            ; lcd.s defines these itself
    .import lcdSetup, lcdClear, lcdCfgCmd, lcdWriteChar
    .import lcdCursU, lcdCursD, lcdCursL, lcdCursR, lcdNewline
.endif

; LCD Instruction breakout (for lcdCfgCmd)
LCD_CLEAR   =   %00000001 ; Clears LCD & sets DDRAM addr to 0 in counter
LCD_HOME    =   %00000010 ; Sets DDRAM addr to 0 in counter & un-shifts LCD
LCD_BLINK   =   %00001100 ; Sets cursor on/off (b1) and blink (b0)
LCD_CURSR   =   %00010100 ; Moves cursor Right
LCD_CURSL   =   %00010000 ; Moves cursor Left
LCD_SHIFTR  =   %00011100 ; Shifts LCD Right
LCD_SHIFTL  =   %00011000 ; Shifts LCD Left
LCD_FUNC    =   %00100000 ; Sets # lines (b3) & font (b2)

; usage:
; lda #LCD_HOME
; jsr lcdCfgCmd -> homes the LCD
; lda (#LCD_CURSR | #%0010) -> moves cursor 1 posn right
;
; Note: lcdCfgCmd bypasses the driver's bookkeeping. Anything that moves the
; cursor or shifts the display behind its back (LCD_HOME, LCD_SHIFTx,
; Set-DDRAM-address) leaves the driver's idea of the cursor out of date. Use
; lcdClear / lcdCurs* / lcdNewline for those.

;------------------------------------------------------------------------------
; --- 16x02 Character LCD Constants ---
;------------------------------------------------------------------------------
E  = %00000100          ; LCD enable signal   -> PB2
RW = %00000010          ; LCD read/write sig  -> PB1
RS = %00000001          ; LCD register select -> PB0

; 16x2
LCDROWS = 2
LCDCOLS = 16

; 20x4
; LCDROWS = 4
; LCDCOLS = 20

.endif