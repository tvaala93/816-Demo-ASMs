; ============================================================
; helloNewWorld.s
;
; Application entry point. Wires together board init (VIA) and
; the LCD driver to print "Hello, world!" on power-up.
;
; Board- and peripheral-specific details live in lib/ -- this
; file should only contain THIS PROGRAM's logic: what order to
; call things in, and what to actually do.
; ============================================================

  .setcpu "65816"
  .a8
  .i8
  .smart

.import viaInit
.import lcdInit
.import lcdCfgCmd
.import lcdWriteChar

.segment "CODE"

reset:
  sei  ; disable interrupts
  clc
  xce   ; ensure emulation mode (E=1) -- this is the
        ; standard 65816 startup idiom, though on
        ; power-up/reset E is already 1 by hardware
  ldx #$ff          ; Setup stack to begin at 0x01ff
  txs

  jsr viaInit

  ; -- LCD Setup --
  ; PB7 PB6 PB5 PB4 PB3 PB2 PB1 PB0
  ; NUL DB7 DB6 DB5 DB4 E   RW  RS

  jsr lcdInit
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcdCfgCmd
  lda #%00001110 ; Display on, cursor on, blink off
  jsr lcdCfgCmd
  lda #%00000110 ; Increment cursor, don't scroll
  jsr lcdCfgCmd
  lda #%00000001 ; Clear the display
  jsr lcdCfgCmd

; -------------------------------------
; Main loop
; -------------------------------------
  ldx #0
writeHelloWorld:
  lda message,x
  beq loop
  jsr lcdWriteChar
  inx
  jmp writeHelloWorld

loop:
  jmp loop

.segment "RODATA"
message:
  .asciiz "Hello, new world!"

; Setup code from reset vector fffc, fffd
.segment "VECTORS"
  .word reset       ; NMI vector   ($FFFA/FFFB -> mirrors to $9FFA on this chip)
  .word reset       ; RESET vector ($FFFC/FFFD -> mirrors to $9FFC on this chip)
  .word $0000       ; IRQ/BRK vector ($FFFE/FFFF -> mirrors to $9FFE on this chip)