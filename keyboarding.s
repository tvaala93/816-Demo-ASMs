; =============================================================================
; keyboarding.s -- demo main program built on the lcd.s and ps2KB.s libraries
; =============================================================================
    .setcpu "65816"
    .a8
    .i8
    .smart
 
    .include "thru_defs.inc"
    .include "lcd.inc"      ; each driver's header imports its own routines
    .include "ps2KB.inc"
 
.segment "CODE"
 
reset:
    sei                 ; disable interrupts
    ldx #$FF            ; Setup stack to begin at 0x01ff
    txs
 
    lda #$7F
    sta IER             ; Disable all VIA interrupt sources
    sta IFR             ; Clear pending VIA interrupt flags
 
    jsr lcdSetup
    jsr kbInit          ; enables the keyboard's CA1 interrupt
    cli
 
    ldx #0
@msg:
    lda message,x
    beq loop
    jsr lcdWriteChar
    inx
    jmp @msg
 
; -------------------------------------
; Main loop: act on each key the driver hands back
; -------------------------------------
loop:
    jsr kbGetKey        ; C=1 and A=key if a key was pressed
    bcc loop
 
    cmp #KEY_ENTER
    beq enter_press
    cmp #KEY_ESC
    beq esc_press
    cmp #KEY_BACK
    beq backspace_press
    cmp #KEY_UP
    beq up_press
    cmp #KEY_DOWN
    beq dn_press
    cmp #KEY_LEFT
    beq lt_press
    cmp #KEY_RIGHT
    beq rt_press
 
    cmp #$20            ; ignore any other control code,
    bcc loop
    cmp #KEY_DEL        ; delete, and arrows we don't handle
    bcs loop
    jsr lcdWriteChar    ; printable character
    jmp loop
 
enter_press:
    jsr lcdNewline      ; start of next row
    jmp loop
 
esc_press:
    jsr lcdClear        ; Clear the screen
    jmp loop
 
backspace_press:
    ; TODO - this just moves the cursor 1 posn left, not true backspace
    jsr lcdCursL
    jmp loop
 
up_press:
    jsr lcdCursU
    jmp loop
 
dn_press:
    jsr lcdCursD
    jmp loop
 
lt_press:
    jsr lcdCursL
    jmp loop
 
rt_press:
    jsr lcdCursR
    jmp loop
 
nmi:
    rti
 
.segment "RODATA"
message:
    .asciiz "Hello!"
 
.segment "VECTORS"
    .word nmi
    .word reset
    .word kbIRQ
 