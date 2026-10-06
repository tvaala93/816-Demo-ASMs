; -- W65C816S specific directives --
  .setcpu "65816"
  .a8              ; tell assembler accumulator is 8-bit
  .i8              ; tell assembler index registers (X/Y) are 8-bit
  .smart           ; let ca65 auto-track register widths after rep/sep


.segment "CODE"

reset:
  sei  ; disable interrupts
  clc
  xce   ; ensure emulation mode (E=1) — this is the
        ; standard 65816 startup idiom, though on
        ; power-up/reset E is already 1 by hardware
  ldx #$ff          ; Setup stack to begin at 0x01ff
  txs

lda #$0
sta $1234
lda #$1
sta $1234
lda #$2
sta $1234
lda #$3
sta $1234
lda #$4
sta $1234
lda #$5
sta $1234
lda #$6
sta $1234
lda #$7
sta $1234
lda #$8
sta $1234

lda #%10101010
sta $1000
lda #%11001100
sta $1001
lda #$ff
sta $1002
lda $1000
lda $1001
lda $1002
adc #$1
sta $1002

done:
  adc #$1
  sta $1003
  jmp done


; Setup code from reset vector fffc, fffd
.segment "VECTORS"
  ;.org $fffc
  .word reset       ; NMI vector   ($FFFA/FFFB -> mirrors to $9FFA on this chip)
  .word reset       ; RESET vector ($FFFC/FFFD -> mirrors to $9FFC on this chip)
  .word $0000       ; IRQ/BRK vector ($FFFE/FFFF -> mirrors to $9FFE on this chip)
  ;.org $fffc
  ;.word reset
  ;.word $0000