; =============================================================================
; test_lcd.s -- Test script to isolate and validate /lib/lcd.s API points
; Accessible API points include:
; - lcdInit
; - lcdCfgCmd
; - lcdWriteChar
; =============================================================================

    .setcpu "65816"
    .a8
    .i8
    .smart

    .include "thru_defs.inc"
    .import lcdSetup, lcdCfgCmd, lcdWriteChar

    .segment "CODE"
reset:
    sei
    ldx #$ff
    txs                     ; emulation mode: SP = $01FF, as your comment intended    
    jsr lcdSetup

    ldx #$00
printToLcd:
    lda message, X
    beq testCfgCmds
    jsr lcdWriteChar
    inx
    jmp printToLcd

testCfgCmds:
    lda #$00
    ; 1 - Toggle cursor blink
    lda #(LCD_BLINK | %00000001)
    jsr lcdCfgCmd
    ; 2 - Move cursor home
    lda #LCD_HOME
    jsr lcdCfgCmd
    ; 3 - Move cursor right
    lda #LCD_CURSR
    jsr lcdCfgCmd
    ; 4 - Move cursor left
    lda #LCD_CURSL
    jsr lcdCfgCmd
    ; 5 - Shift entire display left
    lda #LCD_SHIFTL
    jsr lcdCfgCmd
    ; 6 - Shift entire display right
    lda #LCD_SHIFTR
    jsr lcdCfgCmd
    ; 7 - clear display
    lda #LCD_CLEAR
    jsr lcdCfgCmd

    ldx #$00
printOver:
    lda over, X
    beq done
    jsr lcdWriteChar
    inx
    jmp printOver

done:
    jmp done

    .segment "RODATA"
message:
    .asciiz "test_lcd.s"
over:
    .asciiz "Test Over"

STD_VECTORS